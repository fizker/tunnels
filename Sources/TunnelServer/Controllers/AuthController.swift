import Vapor

class AuthController {
	let req: Request

	init(request: Request) {
		self.req = request
	}

	func summary() async throws -> String {
		"Not logged in"
	}
}

extension Request {
	func authController() -> AuthController {
		.init(request: self)
	}
}
