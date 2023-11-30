import XCTest
@testable import TunnelServer
import Vapor

final class UserControllerTests: XCTestCase {
	let adminUser = User(username: "admin", password: "1234", scopes: [.admin])

	func test__upsertUser__insertingNewUser_passwordPresent_scopeMissing_usernameIsNotColliding__userIsInserted() async throws {
		let upsertRequest = UpsertUserRequest(username: "foo", password: "bar")
		let testStore = UserStore()
		var users = await testStore.users()

		let request = try request(method: .PUT, body: upsertRequest, parameters: ["username": "foo"])

		let controller = try UserController(request: request, userStore: testStore)
		let result = try await controller.upsertUser(usernameParam: "username")

		XCTAssertEqual(result, User(username: "foo", password: "bar", scopes: []))
		users.append(result)
		let updatedUsers = await testStore.users()
		XCTAssertEqual(updatedUsers, users)
	}

	func test__upsertUser__insertingNewUser_passwordIsMissing_scopeMissing_usernameIsNotColliding__errorThrown_userIsNotInserted() async throws {
		let upsertRequest = UpsertUserRequest(username: "foo", password: nil)
		let testStore = UserStore()
		let users = await testStore.users()

		let request = try request(method: .PUT, body: upsertRequest, parameters: ["username": "foo"])

		let controller = try UserController(request: request, userStore: testStore)

		do {
			_ = try await controller.upsertUser(usernameParam: "username")
			XCTFail("Expected a throw")
		} catch {
			guard let error = error as? AbortError
			else { throw error }

			XCTAssertEqual(error.status, .badRequest)
			XCTAssertEqual(error.reason, "New users must have a password")
		}

		let updatedUsers = await testStore.users()
		XCTAssertEqual(updatedUsers, users)
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
