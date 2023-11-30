import Vapor

class UserController {
	let req: Request
	let userStore: UserStore
	let currentUser: User

	init(request: Request, userStore: UserStore) throws {
		self.req = request
		self.userStore = userStore
		self.currentUser = try request.auth.require()
	}

	func users() async -> [User] {
		return await userStore.users()
	}

	func upsertUser(usernameParam: String) async throws -> User {
		let username = try req.parameters.require(usernameParam)
		let user = try req.content.decode(User.self)

		if user.scopes.contains(.sysadmin) && !currentUser.scopes.contains(.sysadmin) {
			throw Abort(.forbidden, reason: "Only sysadmin can set other users to be sysadmin")
		}

		try await userStore.upsert(user: user, oldUsername: username)

		return user
	}
}

extension Request {
	func userController() throws -> UserController {
		try .init(request: self, userStore: application.userStore)
	}
}

extension User: Content {
}
