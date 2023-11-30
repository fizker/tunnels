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
		let upsertRequest = try req.content.decode(UpsertUserRequest.self)

		let oldUser = await userStore.user(username: username)
		guard let password = upsertRequest.password ?? oldUser?.password
		else { throw Abort(.badRequest, reason: "New users must have a password") }

		let scopes = upsertRequest.scopes ?? oldUser?.scopes ?? []

		let user = User(username: upsertRequest.username, password: password, scopes: scopes)

		if user.scopes.contains(.sysadmin) && !currentUser.scopes.contains(.sysadmin) {
			throw Abort(.forbidden, reason: "Only sysadmin can set other users to be sysadmin")
		}

		try await userStore.upsert(user: user, oldUsername: username)

		return user
	}

	func removeUser(usernameParam: String) async throws {
		let username = try req.parameters.require(usernameParam)

		guard let scope = currentUser.scopes.sorted().last
		else { throw Abort(.forbidden) }

		try await userStore.remove(username: username, scopeOfCurrentUser: scope)
	}
}

struct UpsertUserRequest: Codable {
	var username: String
	var scopes: Set<User.Scope>?
	var password: String?
}

extension Request {
	func userController() throws -> UserController {
		try .init(request: self, userStore: application.userStore)
	}
}

extension User: Content {
}
