import XCTest
import XCTVapor
@testable import DebugServer

final class BigFileTests: XCTestCase {
	func test__reasonablyBigFileRequests__fileIsReceived_sizeIsCorrect_shasumMatches() async throws {
		let app = Application(.testing)

		try await DebugServer.configure(app)

		let size = 123_456

		let path = "big-file?size=\(size)"
		try app.test(.GET, path) { res in
			var body = res.body
			let data = body.readData(length: body.readableBytes)!
			XCTAssertEqual(data.count, size)

			let actualDigest = SHA256.hash(data: data)
			let expectedDigest = res.headers.first(name: "x-digest-value")
			XCTAssertEqual(expectedDigest, actualDigest.hex)
		}
	}

	func test__10mb_bigFileRequests__fileIsReceived_sizeIsCorrect_shasumMatches() async throws {
		let app = Application(.testing)

		try await DebugServer.configure(app)

		let size = 10_000_000

		let path = "big-file?size=\(size)"
		try app.test(.GET, path) { res in
			var body = res.body
			let data = body.readData(length: body.readableBytes)!
			XCTAssertEqual(data.count, size)

			let actualDigest = SHA256.hash(data: data)
			let expectedDigest = res.headers.first(name: "x-digest-value")
			XCTAssertEqual(expectedDigest, actualDigest.hex)
		}
	}
}
