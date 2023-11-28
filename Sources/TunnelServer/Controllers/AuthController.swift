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
		"Not logged in"
	}

	func oauth2Token(req: Request) async throws -> AccessTokenResponse {
		guard let request = try? req.content.decode(GrantRequest.self)
		else { throw ErrorResponse(code: .invalidRequest, description: try! .init("Could not parse request")) }

		switch request {
		case .authCodeAccessToken(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		case .clientCredentialsAccessToken(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		case let .passwordAccessToken(request):
			guard let user = await userStore.user(username: request.username, password: request.password)
			else {
				throw ErrorResponse(code: .invalidGrant, description: try .init("Invalid credentials"))
			}

			let login = Login(user: user)
			await userStore.add(login)
			return login.accessTokenResponse(type: .bearer)
		case .refreshToken(_):
			throw ErrorResponse(code: .unsupportedGrantType, description: nil)
		}
	}
}

extension Request {
	func authController() -> AuthController {
		.init(request: self, userStore: application.userStore)
	}
}

extension AccessTokenResponse: Content {
}
