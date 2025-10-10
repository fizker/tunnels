import ACME
import Foundation
import helpers
import Testing

struct ACMESetupTests {
	static let endpointsAndValues: [(ACMEEndpoint, String)] = [
		(.letsEncryptV2Production, "https://acme-v02.api.letsencrypt.org/directory"),
		(.letsEncryptV2Staging, "https://acme-staging-v02.api.letsencrypt.org/directory"),
	]

	@Test
	func encode__outputsExpectedJSON() async throws {
		let setup = ACMESetup(
			host: "example.com",
			endpoint: .letsEncryptV2Production,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		let json = try encode(setup)

		#expect(json == """
		{
		  "contactEmail" : "contact@example.com",
		  "endpoint" : "https://acme-v02.api.letsencrypt.org/directory",
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		""")
	}

	@Test(arguments: endpointsAndValues)
	func initWithDecoder__AcmeSwiftStyleJSON__parsesJSONCorrectly(expectedEndpoint: ACMEEndpoint, url: String) async throws {
		let json = """
		{
		  "contactEmail" : "contact@example.com",
		  "endpoint" : {
		    "relative" : "\(url)"
		  },
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		"""

		let actual = try decode(json) as ACMESetup

		let expected = ACMESetup(
			host: "example.com",
			endpoint: expectedEndpoint,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		#expect(actual == expected)
	}

	@Test(arguments: endpointsAndValues)
	func initWithDecoder__nativeStyleJSON__parsesJSONCorrectly(expectedEndpoint: ACMEEndpoint, url: String) async throws {
		let json = """
		{
		  "contactEmail" : "contact@example.com",
		  "endpoint" : "\(url)",
		  "host" : "example.com",
		  "storagePath" : "/some/path"
		}
		"""

		let actual = try decode(json) as ACMESetup

		let expected = ACMESetup(
			host: "example.com",
			endpoint: expectedEndpoint,
			contactEmail: "contact@example.com",
			storagePath: "/some/path",
		)

		#expect(actual == expected)
	}
}
