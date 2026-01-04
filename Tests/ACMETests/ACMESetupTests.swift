import ACME
import ACMEClientModels
import Foundation
import helpers
import Testing

struct ACMESetupTests {
	static let directoriesAndValues: [(ACMEDirectory, String)] = [
		(.letsEncryptV2Production, "https://acme-v02.api.letsencrypt.org/directory"),
		(.letsEncryptV2Staging, "https://acme-staging-v02.api.letsencrypt.org/directory"),
	]

	@Test
	func encode__outputsExpectedJSON() async throws {
		let setup = ACMESetup(
			host: "example.com",
			directory: .letsEncryptV2Production,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		let json = try encode(setup)

		#expect(json == """
		{
		  "contactEmail" : "contact@example.com",
		  "directory" : "https://acme-v02.api.letsencrypt.org/directory",
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		""")
	}

	@Test(arguments: directoriesAndValues)
	func initWithDecoder__parsesJSONCorrectly(expectedDirectory: ACMEDirectory, url: String) async throws {
		let json = """
		{
		  "contactEmail" : "contact@example.com",
		  "directory" : "\(url)",
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		"""

		let actual = try decode(json) as ACMESetup

		let expected = ACMESetup(
			host: "example.com",
			directory: expectedDirectory,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		#expect(actual == expected)
	}
}
