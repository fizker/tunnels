import Vapor

class UserController {
	let req: Request
	let userStore: UserStore

	init(request: Request, userStore: UserStore) {
		self.req = request
		self.userStore = userStore
	}

	func users() async -> [User] {
		return await userStore.users()
	}
}

extension Request {
	func userController() -> UserController {
		.init(request: self, userStore: application.userStore)
	}
}

extension User: Content {
}
