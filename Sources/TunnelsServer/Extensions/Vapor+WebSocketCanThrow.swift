import Models
import Vapor

extension RoutesBuilder {
	@preconcurrency
	@discardableResult
	func webSocket(
		_ path: PathComponent...,
		maxFrameSize: WebSocketMaxFrameSize = .`default`,
		shouldUpgrade: @escaping (@Sendable (Request) -> EventLoopFuture<HTTPHeaders?>) = {
			$0.eventLoop.makeSucceededFuture([:])
		},
		onUpgrade: @Sendable @escaping (Request, WebSocket) throws -> ()
	) -> Route {
		return webSocket(path, maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: { req, ws in
			do {
				try onUpgrade(req, ws)
			} catch {
				if let error = error as? TunnelError {
					Task {
						try? await ws.send(.error(error))
					}
					return
				}

				let encoder = JSONEncoder()
				if
					let error = error as? Encodable,
					let data = try? encoder.encode(error),
					let json = String(data: data, encoding: .utf8)
				{
					ws.send(json)
				} else {
					ws.send(error.localizedDescription)
				}
			}
		})
	}
}
