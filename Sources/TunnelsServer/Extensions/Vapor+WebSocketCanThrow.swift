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
		return webSocket(path, maxFrameSize: maxFrameSize, shouldUpgrade: shouldUpgrade, onUpgrade: {
			do {
				try onUpgrade($0, $1)
			} catch {
				let encoder = JSONEncoder()
				if
					let error = error as? Encodable,
					let data = try? encoder.encode(error),
					let json = String(data: data, encoding: .utf8)
				{
					$1.send(json)
				} else {
					$1.send(error.localizedDescription)
				}
			}
		})
	}
}
