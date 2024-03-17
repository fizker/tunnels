import Models
import OAuth2Models
import Vapor

class AuthController {
	let req: Request
	let userStore: UserStore

	init(request: Request, userStore: UserStore) {
		self.req = request
		self.userStore = userStore
	}

	func summary() async throws -> String {
		guard let user = req.auth.get(User.self)
		else { return "Not logged in" }

		return """
		Username: \(user.username)
		Scopes: \(user.scopes)
		"""
	}

	func oauth2Token(req: Request) async throws -> AccessTokenResponse {
		guard let request = try? req.content.decode(GrantRequest.self)
		else { throw ErrorResponse(code: .invalidRequest, description: "Could not parse request") }

		let user: User

		switch request {
		case .authCodeAccessToken(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		case let .clientCredentialsAccessToken(request):
			guard
				let username = request.clientID,
				let secret = request.clientSecret
			else {
				throw ErrorResponse(code: .invalidRequest, description: "ClientID and ClientSecret are required")
			}
			guard
				let u = await userStore.user(username: username),
				u.clientSecret == secret
			else {
				throw ErrorResponse(code: .invalidGrant, description: "Invalid credentials")
			}

			user = u
		case let .passwordAccessToken(request):
			guard
				let u = await userStore.user(username: request.username),
				u.password == request.password
			else {
				throw ErrorResponse(code: .invalidGrant, description: "Invalid credentials")
			}

			user = u
		case .refreshToken(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		case .unknown(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		}

		let login = Login(user: user)
		try await userStore.add(login)
		return login.accessTokenResponse(type: .bearer)
	}

	func clientCredentials(for user: User) -> ClientCredentials? {
		guard let secret = user.clientSecret
		else { return nil }

		return ClientCredentials(clientID: user.username, clientSecret: secret)
	}

	func createClientCredentials(for user: User) async throws -> ClientCredentials {
		let secret = UUID().uuidString

		var user = user
		user.clientSecret = secret

		try await userStore.upsert(user: user, oldUsername: user.username)

		return ClientCredentials(clientID: user.username, clientSecret: secret)
	}

	func removeClientCredentials(for user: User) async throws {
		var user = user

		user.clientSecret = nil

		try await userStore.upsert(user: user, oldUsername: user.username)
	}
}

extension ClientCredentials: Content {
}

extension Request {
	func authController() -> AuthController {
		.init(request: self, userStore: application.userStore)
	}
}

extension AccessTokenResponse: Content {
}
