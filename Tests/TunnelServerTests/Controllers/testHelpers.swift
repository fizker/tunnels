@testable import TunnelServer
import VaporTesting

extension Application {
	func authHeader(for user: User, headers: HTTPHeaders = [:]) async throws -> HTTPHeaders {
		let login = Login(user: user)
		try await userStore.add(login)

		let response = login.accessTokenResponse(type: .bearer)

		var headers = headers
		headers.add(name: "authorization", value: "\(response.type) \(response.accessToken)")

		return headers
	}
}

extension Array where Element == User {
	func first(username: String) -> User? {
		first { $0.username == username }
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
