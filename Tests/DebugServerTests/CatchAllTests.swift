import Testing
import VaporTesting
@testable import DebugServer

struct CatchAllTests {
	@Test
	func get__expectedBodyIsReturned() async throws {
		try await withApp(configure: DebugServer.configure) { app in
			try await app.test(.GET, "foo") { res async throws in
				#expect(res.status == .ok)
				#expect(res.body.string == "Hello World at /foo")
			}
		}
	}
}
