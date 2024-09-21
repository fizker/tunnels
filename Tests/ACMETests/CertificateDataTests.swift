import Testing
@testable import ACME

struct CertificateDataTests {
	let testCert = try! CertificateGenerator(commonName: "test", domains: ["example.com"]).generateSelfSignedCertificate().certificate

	@Test
	func initWithCertificate__certificateCoversSingleDomain__detectsTheEmbeddedDomains() async throws {
		let actual = try CertificateData(certificate: testCert, isSelfSigned: true)
		#expect(actual.domains == ["example.com"])
	}

	@Test
	func initWithCertificate__certificateCoversMultipleDomains__detectsTheEmbeddedDomains() async throws {
		let testCert = try CertificateGenerator(commonName: "test", domains: [
			"example.com",
			"foo.example.com",
			"bar.baz.example.com",
		]).generateSelfSignedCertificate().certificate
		let actual = try CertificateData(certificate: testCert, isSelfSigned: true)
		#expect(actual.domains == [
			"example.com",
			"foo.example.com",
			"bar.baz.example.com",
		])
	}

	@Test(arguments: [
		(
			[
				"example.com",
				"foo.example.com",
			], [
				"example.com",
				"foo.example.com",
			]
		),
		(
			[
				"example.com",
				"foo.example.com",
			], [
				"example.com",
			]
		),
		(
			[
				"example.com",
				"foo.example.com",
			], [
				"foo.example.com",
			]
		),
	])
	func coversDomains__correctSubsets__returnsTrue(test: (lhs: [String], rhs: [String])) async throws {
		let (lhs, rhs) = test
		let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
		let isCovered = data.covers(domains: rhs)
		#expect(isCovered, "lhs: \(lhs), rhs: \(rhs)")
	}

	@Test(arguments: [
		(
			[
				"example.com",
			], [
				"example.com",
				"foo.example.com",
			]
		),
		(
			[
				"foo.example.com",
			], [
				"example.com",
				"foo.example.com",
			]
		),
	])
	func coversDomains__incorrectSubsets__returnsFalse(test: (lhs: [String], rhs: [String])) async throws {
		let (lhs, rhs) = test
		let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
		let actual = data.covers(domains: rhs)
		#expect(actual == false)
	}

	@Test(arguments: [
		(
			[
				"*.example.com",
			], [
				"foo.example.com",
				"bar.example.com",
			],
			true
		),
		(
			[
				"example.com",
				"*.example.com",
			], [
				"example.com",
				"foo.example.com",
				"bar.example.com",
			],
			true
		),
		(
			[
				"*.example.com",
			], [
				"example.com",
				"foo.example.com",
			],
			false
		),
		(
			[
				"*.example.com",
			], [
				"foo.example.com",
				"bar.baz.example.com",
			],
			false
		),
	])
	func coversDomains__includesWildcards__matchesCorrectly(test: (lhs: [String], rhs: [String], expected: Bool)) async throws {
		let (lhs, rhs, expected) = test
		let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
		let actual = data.covers(domains: rhs)
		#expect(actual == expected)
	}
}
