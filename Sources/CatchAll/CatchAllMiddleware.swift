import Vapor

public struct CatchAllMiddleware: AsyncMiddleware {
	var handler: @Sendable (Request) -> Response

	public init(handler: @escaping @Sendable (Request) -> Response) {
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

			return handler(request)
		}
	}
}
