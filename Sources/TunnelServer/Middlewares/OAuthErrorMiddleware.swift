import OAuth2Models
import Vapor

/// Catches and returns ``ErrorResponse`` as JSON.
///
/// If this middleware is not present, the default ``Vapor\AbortError`` will be sent instead, which will not be according to OAuth2 spec.
///
/// This middleware needs to be before the default error middleware in order to intercept the ``ErrorResponse``.
struct OAuthErrorMiddleware: AsyncMiddleware {
	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch {
			guard let error = error as? ErrorResponse
			else { throw error }

			let data = try JSONEncoder().encode(error)
			return .init(
				status: status(for: error.code),
				version: request.version,
				headersNoUpdate: [
					"content-length": "\(data.count)",
					"content-type": "application/json",
				],
				body: .init(data: data)
			)
		}
	}

	private func status(for code: ErrorResponse.ErrorCode) -> HTTPResponseStatus {
		switch code {
		case .invalidRequest:
			.badRequest
		case .invalidClient:
			.unauthorized
		case .invalidGrant:
			.unauthorized
		case .unauthorizedClient:
			.unauthorized
		case .unsupportedGrantType:
			.badRequest
		case .accessDenied:
			.forbidden
		case .unsupportedResponseType:
			.badRequest
		case .invalidScope:
			.badRequest
		case .serverError:
			.internalServerError
		case .temporarilyUnavailable:
			.serviceUnavailable
		}
	}
}
