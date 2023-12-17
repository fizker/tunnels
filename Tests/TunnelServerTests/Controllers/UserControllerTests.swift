import XCTest
@testable import TunnelServer
import Vapor

final class UserControllerTests: XCTestCase {
	let usernameParam = "username"
	static let adminUser = User(username: "admin", password: "1234", scopes: [.admin])
	static let sysadminUser = User(username: "sys", password: "1234", scopes: [.sysadmin])

	func test__upsertUser__insertingNewUser_passwordPresent_scopeMissing_usernameIsNotColliding__userIsInserted() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: nil, password: "bar")

		let controller = try UserController(request: request, userStore: userStore)
		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(result, User(username: "foo", password: "bar", scopes: []))
		users.append(result)
		let updatedUsers = await userStore.users()
		XCTAssertEqual(updatedUsers, users)
	}

	func test__upsertUser__insertingNewUser_passwordIsMissing_scopeMissing_usernameIsNotColliding__errorThrown_userIsNotInserted() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: nil, password: nil)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			_ = try await controller.upsertUser(usernameParam: usernameParam)
			XCTFail("Expected a throw")
		} catch {
			guard let error = error as? any AbortError
			else { throw error }

			XCTAssertEqual(error.status, .badRequest)
			XCTAssertEqual(error.reason, "New users must have a password")
		}

		let updatedUsers = await userStore.users()
		XCTAssertEqual(updatedUsers, users)
	}

	func test__upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotInserted() async throws {
		let userStore = try UserStore(storagePath: nil)

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar", loggedInUser: Self.adminUser)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			_ = try await controller.upsertUser(usernameParam: usernameParam)
			XCTFail("Expected a throw")
		} catch {
			guard let error = error as? any AbortError
			else { throw error }

			XCTAssertEqual(error.status, .forbidden)
		}

		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__insertingNewUser_addingSysadminScope_loggedInUserIsSysadmin__userIsInserted() async throws {
		let userStore = try UserStore(storagePath: nil)

		var users = await userStore.users(includeSysAdmin: true)

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: "bar", loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(result, User(username: "foo", password: "bar", scopes: [.sysadmin]))

		users.append(result)
		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsNotChanged__userIsUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let users = await userStore.users()
		let request = try upsertUserRequest(username: "foo", scopes: nil, password: nil)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(user, result)

		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_passwordIsDifferent_scopeIsDifferent_usernameIsNotChanged__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo", scopes: [], password: "baz")

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(User(username: "foo", password: "baz"), result)
		users.append(result)

		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsNotColliding__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users()

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo2", scopes: nil, password: nil, oldUsername: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(User(username: "foo2", password: "bar", scopes: [.admin]), result)

		users.append(result)
		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsChanged_usernameIsColliding__errorThrown_userIsNotUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")
		try await userStore.upsert(user: User(username: "foo2", password: "baz"), oldUsername: "foo2")

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo2", scopes: nil, password: nil, oldUsername: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		do {
			_ = try await controller.upsertUser(usernameParam: usernameParam)
			XCTFail("Expected a throw")
		} catch UserStore.Error.usernameExists {
		}

		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsNotSysadmin__throwsError_userIsNotUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil, loggedInUser: Self.adminUser)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			_ = try await controller.upsertUser(usernameParam: usernameParam)
			XCTFail("Expected a throw")
		} catch {
			guard let error = error as? any AbortError
			else { throw error }

			XCTAssertEqual(error.status, .forbidden)
		}

		let updatedUsers = await userStore.users()
		XCTAssertEqual(users, updatedUsers)
	}

	func test__upsertUser__updatingExistingUser_addingSysadminScope_loggedInUserIsSysadmin__userIsUpdated() async throws {
		let userStore = try UserStore(storagePath: nil)

		var users = await userStore.users(includeSysAdmin: true)

		let user = User(username: "foo", password: "bar", scopes: [.admin])
		try await userStore.upsert(user: user, oldUsername: "foo")

		let request = try upsertUserRequest(username: "foo", scopes: [.sysadmin], password: nil, loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		let result = try await controller.upsertUser(usernameParam: usernameParam)

		XCTAssertEqual(result, User(username: "foo", password: "bar", scopes: [.sysadmin]))

		users.append(result)
		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__nonExistingUser__doesNotThrow_usersAreUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		let request = try removeRequest(username: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		try await controller.removeUser(usernameParam: usernameParam)

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasNoScope__userIsRemoved() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		try await userStore.upsert(user: User(username: "foo", password: "bar"), oldUsername: "foo")

		let request = try removeRequest(username: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		try await controller.removeUser(usernameParam: usernameParam)

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasAdminScope_multipleUsersWithAdminScope__userIsRemoved() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		try await userStore.upsert(user: User(username: "foo", password: "bar", scopes: [.admin]), oldUsername: "foo")

		let request = try removeRequest(username: "foo")

		let controller = try UserController(request: request, userStore: userStore)

		try await controller.removeUser(usernameParam: usernameParam)

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasAdminScope_lastUserWithAdminScope_loggedInUserIsAdmin__throws_usersAreUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		XCTAssertEqual(users.filter { $0.scopes.contains(.admin) }.count, 1)
		guard let adminUser = users.first(where: { $0.scopes.contains(.admin) })
		else { return }

		let request = try removeRequest(username: adminUser.username)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			try await controller.removeUser(usernameParam: usernameParam)
			XCTFail("Expected to throw")
		} catch UserStore.Error.cannotRemoveLastAdmin {
		}

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasAdminScope_lastUserWithAdminScope_loggedInUserIsSysadmin__userIsRemoved() async throws {
		let userStore = try UserStore(storagePath: nil)
		var users = await userStore.users(includeSysAdmin: true)

		XCTAssertEqual(users.filter { $0.scopes.contains(.admin) }.count, 1)
		guard let adminUser = users.first(where: { $0.scopes.contains(.admin) })
		else { return }

		let request = try removeRequest(username: adminUser.username, loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		try await controller.removeUser(usernameParam: usernameParam)

		users.removeAll { $0.scopes.contains(.admin) }
		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasSysadminScope_multipleUsersWithSysadminScope_loggedInUserIsAdmin__throwsError_usersAreUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)

		try await userStore.upsert(user: User(username: "foo", password: "bar", scopes: [.sysadmin]), oldUsername: "foo")
		let users = await userStore.users(includeSysAdmin: true)

		let request = try removeRequest(username: "foo", loggedInUser: Self.adminUser)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			try await controller.removeUser(usernameParam: usernameParam)
			XCTFail("Expected to throw")
		} catch UserStore.Error.adminsCannotRemoveSysadmin {
		}

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasSysadminScope_multipleUsersWithSysadminScope_loggedInUserIsSysadmin__userIsRemoved() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		try await userStore.upsert(user: User(username: "foo", password: "bar", scopes: [.sysadmin]), oldUsername: "foo")

		let request = try removeRequest(username: "foo", loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		try await controller.removeUser(usernameParam: usernameParam)

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func test__removeUser__userExists_userHasSysadminScope_lastUserWithSysadminScope__throws_usersAreUnchanged() async throws {
		let userStore = try UserStore(storagePath: nil)
		let users = await userStore.users(includeSysAdmin: true)

		XCTAssertEqual(users.filter { $0.scopes.contains(.sysadmin) }.count, 1)
		guard let adminUser = users.first(where: { $0.scopes.contains(.sysadmin) })
		else { return }

		let request = try removeRequest(username: adminUser.username, loggedInUser: Self.sysadminUser)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			try await controller.removeUser(usernameParam: usernameParam)
			XCTFail("Expected to throw")
		} catch UserStore.Error.cannotRemoveLastSysadmin {
		}

		let updatedUsers = await userStore.users(includeSysAdmin: true)
		XCTAssertEqual(users, updatedUsers)
	}

	func removeRequest(username: String, loggedInUser: User = adminUser) throws -> Request {
		return try request(method: .DELETE, body: nil, parameters: [usernameParam: username], loggedInUser: loggedInUser)
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
