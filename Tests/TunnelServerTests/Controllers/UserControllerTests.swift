import Testing
@testable import TunnelServer
import Vapor
import VaporTesting

// This hangs if it is not serialized
@Suite(.serialized)
struct UserControllerTests {
	let adminUsername = "admin"
	let sysadminUsername = "sys"

	@Test
	func upsertUser__insertingNewUser_passwordPresent_scopeMissing_usernameIsNotColliding__userIsInserted() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			var users = await userStore.users()

			let adminUser = try #require(users.first { $0.username == adminUsername })
			let headers = try await authHeader(for: adminUser, in: app)

			let newUser = User(username: "foo", password: "bar", scopes: [])
			let request = UpsertUserRequest(username: "foo", scopes: nil, password: "bar")

			try await app.testing().test(.PUT, "/users/foo", headers: headers, body: request) { res in
				#expect(res.status == .ok)

				let result = try res.content.decode(User.self)
				#expect(result == newUser)
				users.append(result)
				let updatedUsers = await userStore.users()
				#expect(updatedUsers == users)
			}
		}
	}

	@Test
	func upsertUser__insertingNewUser_passwordIsMissing_scopeMissing_usernameIsNotColliding__errorThrown_userIsNotInserted() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			let users = await userStore.users()

			let adminUser = try #require(users.first { $0.username == adminUsername })
			let headers = try await authHeader(for: adminUser, in: app)

			let request = UpsertUserRequest(username: "foo", scopes: nil, password: nil)

			try await app.testing().test(.PUT, "/users/foo", headers: headers, body: request) { res in
				#expect(res.status == .badRequest)
				let error = try res.content.decode(VaporErrorResponse<String>.self)
				#expect(error.reason == "New users must have a password")
			}

			let updatedUsers = await userStore.users()
			#expect(updatedUsers == users)
		}
	}

	@Test
	func upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotInserted() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			let users = await userStore.users()

			let currentUser = try #require(users.first { $0.username == adminUsername })
			let headers = try await authHeader(for: currentUser, in: app)

			let newUser = User(username: "foo", password: "bar", scopes: [.sysadmin])

			let request = UpsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar")

			try await app.testing().test(.PUT, newUser.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .forbidden)
			}

			let updatedUsers = await userStore.users()
			#expect(users == updatedUsers)
		}
	}

	@Test
	func upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsSysadmin__userIsInserted() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			var users = await userStore.users(includeSysAdmin: true)

			let sysadminUser = try #require(users.first { $0.username == sysadminUsername })
			let headers = try await authHeader(for: sysadminUser, in: app)

			let expectedUser = User(username: "foo", password: "bar", scopes: [.sysadmin])
			let request = UpsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar")

			try await app.testing().test(.PUT, expectedUser.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .ok)

				let result = try res.content.decode(User.self)
				#expect(result == expectedUser)

				users.append(result)
				let updatedUsers = await userStore.users(includeSysAdmin: true)
				#expect(users == updatedUsers)
			}
		}
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsNotChanged__200IsReturned_userIsUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")

			let users = await userStore.users()

			let adminUser = try #require(users.first { $0.username == adminUsername })
			let headers = try await authHeader(for: adminUser, in: app)

			let request = UpsertUserRequest(username: "foo", scopes: nil, password: nil)

			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .ok)

				let result = try res.content.decode(User.self)
				#expect(user == result)

				let updatedUsers = await userStore.users()
				#expect(users == updatedUsers)
			}
		}
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsDifferent_scopeIsDifferent_usernameIsNotChanged__userIsUpdated() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			var users = await userStore.users()

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")

			let request = UpsertUserRequest(username: "foo", scopes: [], password: "baz")

			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .ok)

				let result = try res.content.decode(User.self)
				#expect(User(username: "foo", password: "baz") == result)
				users.append(result)

				let updatedUsers = await userStore.users()
				#expect(users == updatedUsers)
			}
		}
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsNotColliding__userIsUpdated() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore
			var users = await userStore.users()

			let adminUser = try #require(users.first { $0.scopes.contains(.admin) })
			let headers = try await authHeader(for: adminUser, in: app)

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")

			let request = UpsertUserRequest(username: "foo2", scopes: nil, password: nil)
			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .ok)

				let result = try res.content.decode(User.self)
				#expect(User(username: "foo2", password: "bar", scopes: [.admin]) == result)

				users.append(result)
				let updatedUsers = await userStore.users()
				#expect(users == updatedUsers)
			}
		}
	}

	@Test
	func upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsColliding__errorThrown_userIsNotUpdated() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")
			try await userStore.upsert(user: User(username: "foo2", password: "baz"), oldUsername: "foo2")

			let users = await userStore.users()

			let adminUser = try #require(users.first { $0.username == adminUsername })
			let headers = try await authHeader(for: adminUser, in: app)

			let request = UpsertUserRequest(username: "foo2", scopes: nil, password: nil)
			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .badRequest)
				let error = try res.content.decode(VaporErrorResponse<UserStore.Error>.self)
				#expect(error.reason == .usernameExists)
			}

			let updatedUsers = await userStore.users()
			#expect(users == updatedUsers)
		}
	}

	@Test
	func upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotUpdated() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			let maybeAdminUser = await userStore.users().first { $0.scopes.contains(.admin) }
			let adminUser = try #require(maybeAdminUser)
			let headers = try await authHeader(for: adminUser, in: app)

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")

			let users = await userStore.users()

			let request = UpsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil)

			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .init(statusCode: 403))
			}

			let updatedUsers = await userStore.users()
			#expect(users == updatedUsers)
		}
	}

	@Test
	func upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsSysadmin__userIsUpdated() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)
			let userStore = app.userStore

			var users = await userStore.users(includeSysAdmin: true)

			let sysadmin = try #require(users.first { $0.scopes.contains(.sysadmin) })
			let headers = try await authHeader(for: sysadmin, in: app)

			let user = User(username: "foo", password: "bar", scopes: [.admin])
			try await userStore.upsert(user: user, oldUsername: "foo")

			let request = UpsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil)

			try await app.testing().test(.PUT, user.apiPath, headers: headers, body: request) { res in
				#expect(res.status == .ok)
				let result = try res.content.decode(User.self)
				#expect(result == User(username: "foo", password: "bar", scopes: [.sysadmin]))
				users.append(result)
			}

			let updatedUsers = await userStore.users(includeSysAdmin: true)
			#expect(users == updatedUsers)
		}
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

			let adminUser = try #require(users.first { $0.username == adminUsername })
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
}

extension User {
	var apiPath: String { "users/\(username)" }
}

extension TestingApplicationTester {
	@discardableResult
	func test(
		_ method: HTTPMethod,
		_ path: String,
		headers: HTTPHeaders = .init([]),
		body: some Encodable,
		fileID: String = #fileID,
		filePath: String = #filePath,
		line: Int = #line,
		column: Int = #column,
		afterResponse: (TestingHTTPResponse) async throws -> ()
	) async throws -> any TestingApplicationTester {
		let encoder = JSONEncoder()
		let data = try encoder.encode(body)

		var headers = headers
		headers.add(name: "content-type", value: "application/json")

		return try await self.test(
			method,
			path,
			headers: headers,
			body: .init(data: data),
			fileID: fileID,
			filePath: filePath,
			line: line,
			column: column,
			beforeRequest: { _ in },
			afterResponse: afterResponse
		)
	}
}
