import XCTest
import XCTVapor
@testable import DebugServer

final class CatchAllTests: XCTestCase {
	func test__get__expectedBodyIsReturned() async throws {
		let app = Application(.testing)
		try await DebugServer.configure(app)

		try app.test(.GET, "foo") { res in
			XCTAssertEqual(res.status, .ok)
			XCTAssertEqual(res.body.string, "Hello World at /foo")
		}
	}
}
