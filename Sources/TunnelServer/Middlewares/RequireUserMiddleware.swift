import Vapor

struct RequireUserMiddleware: SimpleMiddleware {
	var requiredScopes: [User.Scope]

	init(_ scopes: User.Scope...) {
		self.requiredScopes = scopes
	}

	func next(_ request: Request) async throws -> Response? {
		let user = try request.auth.require(User.self)

		if user.scopes.contains(.sysadmin) {
			return nil
		}

		if requiredScopes.isEmpty {
			return nil
		}

		if requiredScopes.allSatisfy(user.scopes.contains) {
			return nil
		}

		throw Abort(.init(statusCode: 403))
	}
}
