import Common
import Foundation
import FzkExtensions
public import Logging
import NIO
import OAuth2Models
import TunnelLogModels
import TunnelModels
import WebSocket
import WebSocketKit
public import WebURL
import WebURLFoundationExtras

public actor Client {
	let logger: Logger
	var serverURL: WebURL
	var webSocketURL: WebURL
	var proxies: [Proxy]
	var webSocket: WebSocketHandler?
	var logStorage: LogStorage
	var credentialsStore: CredentialsStore
	var acmeSetupDownloadPath: WebURL?

	public enum Error: Swift.Error, Sendable {
		case failedToRegisterProxies([Proxy])
	}

	public init?(
		serverURL: WebURL,
		proxies: [Proxy],
		credentials: any Credentials,
		logStorage: LogStorage,
		logLevel: Logger.Level = .info,
		acmeSetupDownloadPath: WebURL?,
	) {
		guard serverURL.path.isEmpty || serverURL.path == "/"
		else { return nil }

		logger = Logger(label: "Client") ~ {
			$0.logLevel = logLevel
		}

		self.credentialsStore = .init(credentials: credentials, serverURL: serverURL)
		self.serverURL = serverURL
		self.webSocketURL = serverURL ~ {
			switch $0.scheme {
			case "http":
				$0.scheme = "ws"
			case "https":
				$0.scheme = "wss"
			default:
				break
			}
		}
		self.proxies = proxies
		self.logStorage = logStorage
		self.acmeSetupDownloadPath = acmeSetupDownloadPath
	}

	public func connect() async throws {
		let authHeader = try await credentialsStore.httpHeaders

		let webSocket = try await withCheckedThrowingContinuation { continuation in
			logger.info("Connecting client", metadata: [
				"serverURL": .string(webSocketURL.serialized()),
			])
			WebSocket.connect(
				to: URL(webSocketURL.appending(path: ["tunnels", "client"]))!,
				headers: authHeader,
				on: MultiThreadedEventLoopGroup.singleton
			) { ws in
				self.logger.info("Client connected")
				let handler = WebSocketHandler(webSocket: ws)
				continuation.resume(returning: handler)
			}.whenFailure { error in
				self.logger.error("Failed to connect", metadata: [
					"error": .string(error.localizedDescription),
				])
				continuation.resume(throwing: error)
			}
		}

		self.webSocket = webSocket

		webSocket.onServerMessage { [weak self] ws, value in
			try await self?.handle(value)
		}

		Task {
			await reconnect()
		}

		try await registerProxies(webSocket: webSocket)

		if let acmeSetupDownloadPath {
			var etagPath = acmeSetupDownloadPath
			etagPath.path += ".etag"
			let etagData = try? Data(contentsOf: etagPath)
			let etag = etagData
				.flatMap { String(data: $0, encoding: .utf8) }?
				.trimmingCharacters(in: .whitespacesAndNewlines)
			logger.info("Asking server for ACME setup data", metadata: [
				"etag": "\(etag, default: "N/A")"
			])
		}
	}

	var pendingProxies: [(continuation: TimedResolution, config: TunnelConfiguration)] = []

	private func register(proxy: Proxy, webSocket: WebSocketHandler, retryCount: Int) async -> Bool {
		guard !proxy.isReadyOnServer
		else { return true }

		guard retryCount >= 0
		else { return false }

		let config = proxy.config
		let deferred = Deferred(becoming: TimedResolution.Result.self)
		let timer = TimedResolution(timeout: .seconds(5), onEnd: { deferred.resolve($0) })
		pendingProxies.append((timer, config))
		defer {
			pendingProxies.removeAll { $0.config.host == config.host }
		}

		do {
			try await webSocket.send(.addTunnel(config))
			switch try await deferred.value {
			case .resolved:
				return true
			case .timedOut:
				pendingProxies.removeAll { $0.config.host == config.host }
				return await register(proxy: proxy, webSocket: webSocket, retryCount: retryCount - 1)
			}
		} catch {
			return false
		}
	}

	/// - parameter retryCount: The number of times that this should be retried. If there is an error when this is zero, an error is thrown.
	private func registerProxies(webSocket: WebSocketHandler, retryCount: Int = 3) async throws {
		await withTaskGroup(of: (host: String, wasRegistered: Bool).self) { group in
			for proxy in proxies where !proxy.isReadyOnServer {
				group.addTask {
					(proxy.config.host, await self.register(proxy: proxy, webSocket: webSocket, retryCount: retryCount))
				}
			}

			// This gives sendable-warning: await group.waitForAll()
			for await _ in group {
			}
		}

		let pendingProxies = proxies.filter { !$0.isReadyOnServer }
		if !pendingProxies.isEmpty {
			logger.error("Some proxies were not registered", metadata: [
				"proxies": .array(pendingProxies.map { "\($0.host)" }),
			])
			throw Error.failedToRegisterProxies(pendingProxies)
		}
	}

	public func waitUntilClose() async throws {
		while true {
			try? await Task.sleep(for: .seconds(60))
		}
	}

	private var reconnectRunning = false
	private func reconnect() async {
		guard !reconnectRunning
		else { return }
		reconnectRunning = true
		defer { reconnectRunning = false }

		while true {
			guard let webSocket = await webSocket?.webSocket
			else { return }

			do {
				try await withCheckedThrowingContinuation { continuation in
					webSocket.onClose.whenComplete {
						continuation.resume(with: $0)
					}
				}
			} catch {
				logger.info("connection lost: \(error)")
			}

			while true {
				logger.info("attempting reconnect...")
				do {
					for index in proxies.indices {
						proxies[index].isReadyOnServer = false
					}

					try await connect()
					logger.info("reconnected")
					break
				} catch {
					logger.info("reconnect failed: \(error)")
					try? await Task.sleep(for: .seconds(5))
				}
			}
		}
	}

	/// Handles a message from the WebSocket connection to the server.
	///
	/// This includes both sending the request to the proxy and handling the response, while adding a log locally.
	func handle(_ message: WebSocketServerMessage) async throws {
		switch message {
		case let .request(req):
			logger.info("Received request", metadata: [
				"id": "\(req.id)",
				"path": "\(req.path)",
				"method": "\(req.method)",
				"host": "\(req.host)",
			])
			var log = Log(request: req)
			let logDetails = await logStorage.add(log)

			let (res, bodyUploader) = try await handle(req, localCopy: logDetails?.requestStream)
			logger.info("Got response", metadata: [
				"id": "\(req.id)",
				"status": "\(res.status)",
			])
			#warning("we should catch errors and log the error")
			log.set(response: res)
			await logStorage.update(log)
			try await webSocket?.send(.response(res))
			try await bodyUploader(logDetails?.responseStream)
			if let logDetails {
				try await logStorage.update(logDetails)
			}
		case let .error(error):
			switch error {
			case let .alreadyBound(host):
				logger.error("Requested host was already bound to another client", metadata: [
					"host": "\(host)",
				])
				proxies.removeAll { $0.host == host }
				if proxies.isEmpty {
					logger.info("Last host rejected. Shutting down client")
					try await webSocket?.close()
				}
			}
		case let .tunnelAdded(config):
			guard let index = proxies.firstIndex(where: { $0.host == config.host })
			else {
				logger.error("Server informed us of adding an unknown host", metadata: [
					"host": "\(config.host)",
				])
				return
			}
			proxies[index].isReadyOnServer = true
			logger.info("Proxy ready", metadata: [
				"host": "\(config.host)",
			])

			guard let idx = pendingProxies.firstIndex(where: { $0.config.host == config.host })
			else { return }
			pendingProxies[idx].continuation.resolve()
		case .tunnelRemoved(_):
			break
		}
	}
}
