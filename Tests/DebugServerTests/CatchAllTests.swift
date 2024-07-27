import XCTest
import XCTVapor
@testable import DebugServer

final class CatchAllTests: XCTestCase {
	func test__get__expectedBodyIsReturned() async throws {
		let app = try await Application.make(.testing)
		defer { Task {
			try await app.asyncShutdown()
		} }

		try await DebugServer.configure(app)

		try await app.test(.GET, "foo") { res async throws in
			XCTAssertEqual(res.status, .ok)
			XCTAssertEqual(res.body.string, "Hello World at /foo")
		}
	}
}
