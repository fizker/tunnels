import Testing
import VaporTesting
@testable import DebugServer

struct BigFileTests {
	@Test
	func reasonablyBigFileRequests__fileIsReceived_sizeIsCorrect_shasumMatches() async throws {
		try await withApp(configure: configure) { app in
			let size = 123_456

			let path = "big-file?size=\(size)"
			try await app.test(.GET, path) { res async throws in
				var body = res.body
				let data = body.readData(length: body.readableBytes)!
				#expect(data.count == size)

				let actualDigest = SHA256.hash(data: data)
				let expectedDigest = res.headers.first(name: "x-digest-value")
				#expect(expectedDigest == actualDigest.hex)
			}
		}
	}

	@Test
	func bigFileRequests_10mb__fileIsReceived_sizeIsCorrect_shasumMatches() async throws {
		try await withApp(configure: configure) { app in
			let size = 10_000_000

			let path = "big-file?size=\(size)"
			try await app.test(.GET, path) { res async throws in
				var body = res.body
				let data = body.readData(length: body.readableBytes)!
				#expect(data.count == size)

				let actualDigest = SHA256.hash(data: data)
				let expectedDigest = res.headers.first(name: "x-digest-value")
				#expect(expectedDigest == actualDigest.hex)
			}
		}
	}
}
