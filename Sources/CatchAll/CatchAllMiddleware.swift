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
			guard
				let error = error as? any AbortError,
				error.status == .notFound
			else { throw error }

			return try await handler(request)
		}
	}
}
