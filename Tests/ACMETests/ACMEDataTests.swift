import ACME
import helpers
import Testing

struct ACMEDataTests {
	static let endpointsAndValues: [(ACMEEndpoint, String)] = [
		(.letsEncryptV2Production, "https://acme-v02.api.letsencrypt.org/directory"),
		(.letsEncryptV2Staging, "https://acme-staging-v02.api.letsencrypt.org/directory"),
	]

	@Test(arguments: endpointsAndValues)
	func encode__noCertificates__encodesCorrectly(endpoint: ACMEEndpoint, url: String) async throws {
		let subject = ACMEData(
			endpoint: endpoint,
			accountKey: "some key",
			certificates: nil,
		)

		let actual = try encode(subject)
		let expected = """
		{
		  "accountKey" : "some key",
		  "endpoint" : "\(url)"
		}
		"""

		#expect(actual == expected)
	}

	@Test(arguments: endpointsAndValues)
	func initFromDecoder__noCertificates_endpointIsAcmeSwiftStyle__decodedCorrectly(endpoint: ACMEEndpoint, url: String) async throws {
		let json = """
		{
		  "accountKey" : "some key",
		  "endpoint" : {
		    "relative" : "\(url)"
		  }
		}
		"""

		let actual = try decode(json) as ACMEData

		let expected = ACMEData(
			endpoint: endpoint,
			accountKey: "some key",
			certificates: nil,
		)

		#expect(actual == expected)
	}

	@Test(arguments: endpointsAndValues)
	func initFromDecoder__noCertificates_endpointIsInternalStyle__decodedCorrectly(endpoint: ACMEEndpoint, url: String) async throws {
		let json = """
		{
		  "accountKey" : "some key",
		  "endpoint" : "\(url)"
		}
		"""

		let actual = try decode(json) as ACMEData

		let expected = ACMEData(
			endpoint: endpoint,
			accountKey: "some key",
			certificates: nil,
		)

		#expect(actual == expected)
	}
}
