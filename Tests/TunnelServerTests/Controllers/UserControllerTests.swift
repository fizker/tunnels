import XCTest
@testable import TunnelServer
import Vapor

final class UserControllerTests: XCTestCase {
	let usernameParam = "username"
	let adminUser = User(username: "admin", password: "1234", scopes: [.admin])

	func test__upsertUser__insertingNewUser_passwordPresent_scopeMissing_usernameIsNotColliding__userIsInserted() async throws {
		let userStore = UserStore()
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
		let userStore = UserStore()
		let users = await userStore.users()

		let request = try upsertUserRequest(username: "foo", scopes: nil, password: nil)

		let controller = try UserController(request: request, userStore: userStore)

		do {
			_ = try await controller.upsertUser(usernameParam: usernameParam)
			XCTFail("Expected a throw")
		} catch {
			guard let error = error as? AbortError
			else { throw error }

			XCTAssertEqual(error.status, .badRequest)
			XCTAssertEqual(error.reason, "New users must have a password")
		}

		let updatedUsers = await userStore.users()
		XCTAssertEqual(updatedUsers, users)
	}

	func test__upsertUser__updatingExistingUser_passwordIsMissing_scopeMissing_usernameIsNotChanged__userIsUnchanged() async throws {
		let userStore = UserStore()

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
		let userStore = UserStore()
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
		let userStore = UserStore()
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
		let userStore = UserStore()

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

	func upsertUserRequest(username: String, scopes: Set<User.Scope>?, password: String?, oldUsername: String? = nil) throws -> Request {
		let upsertRequest = UpsertUserRequest(username: username, scopes: scopes, password: password)
		return try request(method: .PUT, body: upsertRequest, parameters: [usernameParam: oldUsername ?? username])
	}

	func request(method: HTTPMethod, body: any Encodable, parameters: [String: String] = [:]) throws -> Request {
		let app = Application()
		let request = Request(
			application: app,
			method: method,
			url: "",
			headers: [
				"content-type": "application/json",
			],
			collectedBody: try encode(body),
			on: app.eventLoopGroup.any()
		)
		request.parameters = Parameters()
		for (key, value) in parameters {
			request.parameters.set(key, to: value)
		}
		request.auth.login(adminUser)

		return request
	}

	func encode(_ value: any Encodable) throws -> ByteBuffer {
		let data = try JSONEncoder().encode(value)
		return ByteBuffer(data: data)
	}
}
