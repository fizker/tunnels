import ACME
import Foundation
import helpers
import Testing

struct ACMESetupTests {
	@Test
	func encode__outputsExpectedJSON() async throws {
		let setup = ACMESetup(
			host: "example.com",
			endpoint: .letsEncrypt,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		let json = try encode(setup)

		#expect(json == """
		{
		  "contactEmail" : "contact@example.com",
		  "endpoint" : {
		    "relative" : "https://acme-v02.api.letsencrypt.org/directory"
		  },
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		""")
	}

	@Test
	func initWithDecoder__parsesJSONCorrectly() async throws {
		let json = """
		{
		  "contactEmail" : "contact@example.com",
		  "endpoint" : {
		    "relative" : "https://acme-v02.api.letsencrypt.org/directory"
		  },
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		"""

		let actual = try decode(json) as ACMESetup

		let expected = ACMESetup(
			host: "example.com",
			endpoint: .letsEncrypt,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		#expect(actual == expected)
	}
}
