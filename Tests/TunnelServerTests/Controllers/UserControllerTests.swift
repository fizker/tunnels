import Testing
@testable import TunnelServer
import Vapor
import VaporTesting

// This hangs if it is not serialized
@Suite(.serialized)
struct UserControllerTests {
	let usernameParam = "username"
	static let adminUser = User(username: "admin", password: "1234", scopes: [.admin])
	static let sysadminUser = User(username: "sys", password: "1234", scopes: [.sysadmin])

	@Test
	func upsertUser__insertingNewUser_passwordPresent_scopeMissing_usernameIsNotColliding__userIsInserted() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: nil, password: "bar")

		let controller = try UserController(request: request, userStore: userStore)
		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(result == User(username: "foo", password: "bar", scopes: []))
		users.append(result)
		let updatedUsers = await userStore.users()
		#expect(updatedUsers == users)
	}

	@Test
	func upsertUser__insertingNewUser_passwordIsMissing_scopeMissing_usernameIsNotColliding__errorThrown_userIsNotInserted() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: nil, password: nil)

		let controller = try UserController(request: request, userStore: userStore)

		await #expect {
			try await controller.upsertUser(usernameParam: usernameParam)
		} throws: { error in
			guard let error = error as? any AbortError
			else { throw error }

			#expect(error.status == .badRequest)
			#expect(error.reason == "New users must have a password")
			return true
		}

		let updatedUsers = await userStore.users()
		#expect(updatedUsers == users)
	}

	@Test
	func upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotInserted() async throws {
		let userStore = try UserStore(storagePath: nil)

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar", loggedInUser: Self.adminUser)

		let controller = try UserController(request: request, userStore: userStore)

		await #expect {
			try await controller.upsertUser(usernameParam: usernameParam)
		} throws: { error in
			guard let error = error as? any AbortError
			else { throw error }

			#expect(error.status == .forbidden)
			return true
		}

		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsSysadmin__userIsInserted() async throws {
		let userStore = try UserStore(storagePath: nil)

		var users = await userStore.users(includeSysAdmin: true)

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar", loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(result == User(username: "foo", password: "bar", scopes: [.sysadmin]))

		users.append(result)
		let updatedUsers = await userStore.users(includeSysAdmin: true)
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsNotChanged__userIsUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let users = await userStore.users()
		let request = try upsertUserRequest(username: "foo", scopes: nil, password: nil)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(user == result)

		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsDifferent_scopeIsDifferent_usernameIsNotChanged__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo", scopes: [], password: "baz")

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(User(username: "foo", password: "baz") == result)
		users.append(result)

		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsNotColliding__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo2", scopes: nil, password: nil, oldUsername: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(User(username: "foo2", password: "bar", scopes: [.admin]) == result)

		users.append(result)
		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsColliding__errorThrown_userIsNotUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")
		try await userStore.upsert(user: User(username: "foo2", password: "baz"), oldUsername: "foo2")

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo2", scopes: nil, password: nil, oldUsername: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		await #expect(throws: UserStore.Error.usernameExists) {
			try await controller.upsertUser(usernameParam: usernameParam)
		}

		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil, loggedInUser: Self.adminUser)

		let controller = try UserController(request: request, userStore: userStore)

		await #expect { try await controller.upsertUser(usernameParam: usernameParam) } throws: { error in
			guard let error = error as? any AbortError
			else { throw error }

			#expect(error.status == .forbidden)
			return true
		}

		let updatedUsers = await userStore.users()
		#expect(users == updatedUsers)
	}

	@Test
	func upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsSysadmin__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		var users = await userStore.users(includeSysAdmin: true)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil, loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		#expect(result == User(username: "foo", password: "bar", scopes: [.sysadmin]))

		users.append(result)
		let updatedUsers = await userStore.users(includeSysAdmin: true)
		#expect(users == updatedUsers)
	}

	@Test
	func removeUser__nonExistingUser__doesNotThrow_usersAreUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			let users = await userStore.users(includeSysAdmin: true)

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			let nonExistingUser = User(username: "foo", password: "")

			try await app.testing().test(.DELETE, nonExistingUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasNoScope__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			let users = await userStore.users(includeSysAdmin: true)

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			let newUser = User(username: "foo", password: "bar")
			try await userStore.upsert(user: newUser, oldUsername: "foo")

			try await app.testing().test(.DELETE, newUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasAdminScope_multipleUsersWithAdminScope_otherAdminIsTarget__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			let users = await userStore.users(includeSysAdmin: true)

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			let newUser = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: newUser, oldUsername: "foo")

			try await app.testing().test(.DELETE, newUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasAdminScope_multipleUsersWithAdminScope_selfIsTarget__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			let users = await userStore.users(includeSysAdmin: true)

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			try await userStore.upsert(user: User(username: "foo", password: "bar", scopes: [.admin]), oldUsername: "foo")
			var usersWithNewAdmin = await userStore.users(includeSysAdmin: true)

			try await app.testing().test(.DELETE, adminUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			usersWithNewAdmin.removeAll { $0.username == adminUser.username }
			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(usersWithNewAdmin == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasAdminScope_lastUserWithAdminScope_loggedInUserIsAdmin__throws_usersAreUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let userStore = app.userStore
			let users = await userStore.users(includeSysAdmin: true)

			#expect(users.filter { $0.scopes.contains(.admin) }.count == 1)
			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			try await app.testing().test(.DELETE, adminUser.apiPath, headers: headers) { res in
				#expect(res.status == .badRequest)
				let error = try res.content.decode(VaporErrorResponse<UserStore.Error>.self)
				#expect(error.reason == .cannotRemoveLastAdmin)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasAdminScope_lastUserWithAdminScope_loggedInUserIsSysadmin__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let userStore = app.userStore
			var users = await userStore.users(includeSysAdmin: true)

			#expect(users.filter { $0.scopes.contains(.admin) }.count == 1)
			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let sysadminUser = try #require(users.first { $0.scopes.contains(.sysadmin) })
			let headers = try await authHeader(for: sysadminUser, in: app)

			try await app.testing().test(.DELETE, adminUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			users.removeAll { $0.scopes.contains(.admin) }
			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasSysadminScope_multipleUsersWithSysadminScope_loggedInUserIsAdmin__throwsError_usersAreUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			let newUser = User(username: "foo", password: "bar", scopes: [.sysadmin])
			try await userStore.upsert(user: newUser, oldUsername: "foo")
			let users = await userStore.users(includeSysAdmin: true)

			let adminUser = try #require(users.first { $0.username == Self.adminUser.username })
			let headers = try await authHeader(for: adminUser, in: app)

			try await app.testing().test(.DELETE, newUser.apiPath, headers: headers) { res in
				#expect(res.status == .init(statusCode: 403))
				let error = try res.content.decode(VaporErrorResponse<UserStore.Error>.self)
				#expect(error.reason == .adminsCannotRemoveSysadmin)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasSysadminScope_multipleUsersWithSysadminScope_loggedInUserIsSysadmin_currentUserIsTarget__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let userStore = app.userStore

			let users = await userStore.users(includeSysAdmin: true)

			let sysadmin = try #require(users.first { $0.scopes.contains(.sysadmin) })
			let headers = try await authHeader(for: sysadmin, in: app)

			try await userStore.upsert(user: User(username: "foo", password: "bar", scopes: [.sysadmin]), oldUsername: "foo")

			var usersWithNewSysadmin = await userStore.users(includeSysAdmin: true)
			#expect(users != usersWithNewSysadmin)

			try await app.testing().test(.DELETE, sysadmin.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			usersWithNewSysadmin.removeAll { $0.username == sysadmin.username }
			#expect(usersWithNewSysadmin == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasSysadminScope_multipleUsersWithSysadminScope_loggedInUserIsSysadmin_otherSysadminIsTarget__userIsRemoved() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let userStore = app.userStore

			let users = await userStore.users(includeSysAdmin: true)

			let sysadmin = try #require(users.first { $0.scopes.contains(.sysadmin) })
			let headers = try await authHeader(for: sysadmin, in: app)

			let newUser = User(username: "foo", password: "bar", scopes: [.sysadmin])
			try await userStore.upsert(user: newUser, oldUsername: "foo")

			let usersWithNewSysadmin = await userStore.users(includeSysAdmin: true)
			#expect(users != usersWithNewSysadmin)

			try await app.testing().test(.DELETE, newUser.apiPath, headers: headers) { res in
				#expect(res.status == .noContent)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	@Test
	func removeUser__userExists_userHasSysadminScope_lastUserWithSysadminScope__throws_usersAreUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let users = await app.userStore.users(includeSysAdmin: true)

			#expect(users.filter { $0.scopes.contains(.sysadmin) }.count == 1)
			let sysadminUser = try #require(users.first(where: { $0.scopes.contains(.sysadmin) }))
			let headers = try await authHeader(for: sysadminUser, in: app)

			try await app.testing().test(.DELETE, sysadminUser.apiPath, headers: headers) { res in
				#expect(res.status == .badRequest)
				let error = try res.content.decode(VaporErrorResponse<UserStore.Error>.self)
				#expect(error.reason == .cannotRemoveLastSysadmin)
			}

			let updatedUsers = await app.userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
	}

	func authHeader(for user: User, in app: Application, headers: HTTPHeaders = [:]) async throws -> HTTPHeaders {
		let login = Login(user: user)
		try await app.userStore.add(login)

		let response = login.accessTokenResponse(type: .bearer)

		var headers = headers
		headers.add(name: "authorization", value: "\(response.type) \(response.accessToken)")

		return headers
	}

	func upsertUserRequest(username: String, scopes: Set<User.Scope>?, password: String?, oldUsername: String? = nil, loggedInUser: User = adminUser) throws -> Request {
		let upsertRequest = UpsertUserRequest(username: username, scopes: scopes, password: password)
		return try request(method: .PUT, body: upsertRequest, parameters: [usernameParam: oldUsername ?? username], loggedInUser: loggedInUser)
	}

	private func request(method: HTTPMethod, body: (any Encodable)?, parameters: [String: String] = [:], loggedInUser: User) throws -> Request {
		var headers = HTTPHeaders()
		let buffer = try body.map(encode)
		if buffer != nil {
			headers.add(name: "content-type", value: "application/json")
		}

		let app = Application()
		let request = Request(
			application: app,
			method: method,
			url: "",
			headers: headers,
			collectedBody: buffer,
			on: app.eventLoopGroup.any()
		)
		request.parameters = Parameters()
		for (key, value) in parameters {
			request.parameters.set(key, to: value)
		}
		request.auth.login(loggedInUser)

		return request
	}

	func encode(_ value: any Encodable) throws -> ByteBuffer {
		let data = try JSONEncoder().encode(value)
		return ByteBuffer(data: data)
	}
}

extension User {
	var apiPath: String { "users/\(username)" }
}
