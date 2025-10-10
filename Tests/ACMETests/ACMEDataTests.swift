import ACME
import AcmeSwift
import helpers
import Testing

struct ACMEDataTests {
	static let endpointsAndValues: [(AcmeEndpoint, String)] = [
		(.letsEncrypt, "https://acme-v02.api.letsencrypt.org/directory"),
		(.letsEncryptStaging, "https://acme-staging-v02.api.letsencrypt.org/directory"),
	]

	@Test(arguments: endpointsAndValues)
	func encode__noCertificates__encodesCorrectly(endpoint: AcmeEndpoint, url: String) async throws {
		let subject = ACMEData(
			endpoint: endpoint,
			accountKey: "some key",
			certificates: nil,
		)

		let actual = try encode(subject)
		let expected = """
		{
		  "accountKey" : "some key",
		  "endpoint" : {
		    "relative" : "\(url)"
		  }
		}
		"""

		#expect(actual == expected)
	}

	@Test(arguments: endpointsAndValues)
	func initFromDecoder__noCertificates_endpointIsAcmeSwiftStyle__decodedCorrectly(endpoint: AcmeEndpoint, url: String) async throws {
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
}
