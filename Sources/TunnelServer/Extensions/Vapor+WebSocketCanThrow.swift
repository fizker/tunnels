import Common
import Models
import Vapor
import WebSocket

private let coder = Coder()

extension RoutesBuilder {
	@preconcurrency
	@discardableResult
	func webSocket(
		_ path: PathComponent...,
		maxFrameSize: WebSocketMaxFrameSize = .`default`,
		shouldUpgrade: @escaping (@Sendable (Request) -> EventLoopFuture<HTTPHeaders?>) = {
			$0.eventLoop.makeSucceededFuture([:])
		},
		onUpgrade: @Sendable @escaping (Request, WebSocketHandler) throws -> ()
	) -> Route {
		return webSocket(path, maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: { req, ws in
			let handler = WebSocketHandler(webSocket: ws)
			do {
				try onUpgrade(req, handler)
			} catch {
				if let error = error as? TunnelError {
					Task {
						try? await handler.send(.error(error))
					}
					return
				}

				if
					let error = error as? any Encodable,
					let data = try? coder.encode(error),
					let json = String(data: data, encoding: .utf8)
				{
					ws.send(json)
				} else {
					ws.send(error.localizedDescription)
				}
			}
		})
	}

	@preconcurrency
	@discardableResult
	func webSocket(
		_ path: PathComponent...,
		maxFrameSize: WebSocketMaxFrameSize = .`default`,
		shouldUpgrade: @escaping (@Sendable (Request) async throws -> HTTPHeaders?) = { _ in [:] },
		onUpgrade: @Sendable @escaping (Request, WebSocketHandler) async throws -> ()
	) -> Route {
		return self.webSocket(path, maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: { req, ws in
			let handler = WebSocketHandler(webSocket: ws)
			do {
				try await onUpgrade(req, handler)
			} catch {
				if let error = error as? TunnelError {
					Task {
						try? await handler.send(.error(error))
					}
					return
				}

				if
					let error = error as? any Encodable,
					let data = try? coder.encode(error),
					let json = String(data: data, encoding: .utf8)
				{
					try? await ws.send(json)
				} else {
					try? await ws.send(error.localizedDescription)
				}
			}
		})
	}
}
