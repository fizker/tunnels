import XCTest
@testable import TunnelServer
import Common

final class UserTests: XCTestCase {
	let coder = Coder()

	func test__initFromDecoder__jsonDoesNotIncludeHosts__decodesCorrectly() async throws {
		let json = """
		{
			"username": "foo",
			"password": "bar"
		}
		"""

		let actual = try coder.decode(User.self, from: Data(json.utf8))

		let expected = User(username: "foo", password: "bar")

		XCTAssertEqual(actual, expected)
	}
}
