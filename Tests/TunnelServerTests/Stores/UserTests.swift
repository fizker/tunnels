import Testing
@testable import TunnelServer
import Common
import Foundation

struct UserTests {
	let coder = Coder()

	@Test
	func initFromDecoder__jsonDoesNotIncludeHosts__decodesCorrectly() async throws {
		let json = """
		{
			"username": "foo",
			"password": "bar"
		}
		"""

		let actual = try coder.decode(User.self, from: Data(json.utf8))

		let expected = User(username: "foo", password: "bar")

		#expect(actual == expected)
	}
}
