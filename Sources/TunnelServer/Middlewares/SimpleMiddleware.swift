import Vapor

/// Assigns a simple middleware which removes some of the boiler-plate from making middleware
protocol SimpleMiddleware: AsyncMiddleware {
	/// Handles the request.
	/// - parameter requeset: The requeset to handle.
	/// - returns: A  `Response` if this middleware is the end-of-line, or `nil` if the next respondr should be evaluated.
	func next(_ request: Request) async throws -> Response?
}

extension SimpleMiddleware {
	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		if let response = try await self.next(request) {
			return response
		}
		return try await next.respond(to: request)
	}
}
