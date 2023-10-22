import Vapor

extension Optional: AsyncResponseEncodable where Wrapped: AsyncResponseEncodable {
	public func encodeResponse(for request: Request) async throws -> Response {
		guard let value = self.wrapped
		else { return Response.init(status: .notFound) }

		return try await value.encodeResponse(for: request)
	}
}
