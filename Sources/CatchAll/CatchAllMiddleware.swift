import Vapor

public struct CatchAllMiddleware: AsyncMiddleware {
	var handler: @Sendable (Request) async throws -> Response

	public init(handler: @escaping @Sendable (Request) async throws -> Response) {
		self.handler = handler
	}

	public func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch {
			// This requires Vapor to change and make RouteNotFound public
			guard error is RouteNotFound
			else { throw error }

			return try await handler(request)
		}
	}
}
