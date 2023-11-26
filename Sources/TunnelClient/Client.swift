import Foundation
import Logging
import Models
import NIO
import WebSocketKit

let httpSchemeRegex = try! Regex("^http")

public class Client {
	let logger = Logger(label: "Client")
	var serverURL: URL
	var webSocketURL: URL
	var proxies: [Proxy]
	var webSocket: WebSocket?
	var logStorage: LogStorage

	public init?(serverURL: URL, proxies: [Proxy], logStorage: LogStorage) {
		guard serverURL.path().isEmpty || serverURL.path() == "/"
		else { return nil }

		self.serverURL = serverURL
		self.webSocketURL = URL(string: serverURL.absoluteString.replacing(httpSchemeRegex, with: "ws"))!
		self.proxies = proxies
		self.logStorage = logStorage
	}

	public func connect() async throws {
		let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		webSocket = try await withCheckedThrowingContinuation { continuation in
			logger.info("Connecting client", metadata: [
				"serverURL": .string(webSocketURL.absoluteString),
			])
			WebSocket.connect(to: webSocketURL.appending(path: "tunnels/client"), on: elg) { ws in
				self.logger.info("Client connected")
				continuation.resume(returning: ws)
			}.whenFailure { error in
				self.logger.error("Failed to connect", metadata: [
					"error": .string(error.localizedDescription),
				])
				continuation.resume(throwing: error)
			}
		}

		webSocket?.onServerMessage { [weak self] ws, value in
			try await self?.handle(value)
		}

		for proxy in proxies {
			try await webSocket?.send(.addTunnel(proxy.config))
		}
	}

	public func waitUntilClose() async throws {
		guard let webSocket
		else { return }

		try await withCheckedThrowingContinuation { continuation in
			webSocket.onClose.whenComplete {
				continuation.resume(with: $0)
			}
		}
	}

	func handle(_ message: WebSocketServerMessage) async throws {
		switch message {
		case let .request(req):
			logger.info("Received request", metadata: [
				"id": "\(req.id)",
				"path": "\(req.path)",
				"method": "\(req.method)",
				"host": "\(req.host)",
			])
			let start = Date.now
			let res = try await handle(req)
			logger.info("Got response", metadata: [
				"id": "\(req.id)",
				"status": "\(res.status)",
			])
			#warning("we should catch errors and log the error")
			await logStorage.add(Log(
				requestReceived: start,
				responseSent: .now,
				responseTime: start.timeIntervalSinceNow * -1000,
				request: req,
				response: res
			))
			try await webSocket?.send(.response(res))
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
		}
	}
}
