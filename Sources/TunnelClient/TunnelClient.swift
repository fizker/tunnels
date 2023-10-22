import Foundation
import Models
import NIO
import WebSocketKit

public class TunnelClient {
	var proxies: [Proxy]
	var webSocket: WebSocket?

	public init(proxies: [Proxy]) {
		self.proxies = proxies
	}

	public func connect() async throws {
		let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		webSocket = try await withCheckedThrowingContinuation { continuation in
			WebSocket.connect(to: "ws://localhost:8110/tunnels/client", on: elg) { ws in
				continuation.resume(returning: ws)
			}.whenFailure { error in
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
			let res = try await handle(req)
			try await webSocket?.send(.response(res))
		case let .error(error):
			switch error {
			case let .alreadyBound(host):
				print("Error: The requested host \(host) was already bound to another client.")
				proxies.removeAll { $0.host == host }
				if proxies.isEmpty {
					try await webSocket?.close()
				}
			}
		}
	}
}
