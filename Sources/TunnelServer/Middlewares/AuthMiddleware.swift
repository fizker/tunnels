import Vapor

/// A middleware that checks for a login token and attempts to find a matching user.
///
/// It does not enforce that the user exists or adheres to any specific role. It just loads the data so that
/// Vapor´s Request.auth is set correctly.
struct AuthMiddleware: SimpleMiddleware {
	var userStore: UserStore

	func next(_ req: Request) async throws -> Response? {
		guard let auth = req.headers.bearerAuthorization
		else { return nil }

		guard let login = await userStore.login(forToken: auth.token)
		else { throw Abort(.unauthorized) }

		guard login.expiresAt > .now
		else { throw Abort(.unauthorized, reason: "Token expired") }

		req.auth.login(login.user)

		return nil
	}
}
