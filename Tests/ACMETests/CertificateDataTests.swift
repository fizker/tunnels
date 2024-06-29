import XCTest
@testable import ACME

final class CertificateDataTests: XCTestCase {
	let testCert = try! CertificateGenerator(commonName: "test", domains: ["example.com"]).generateSelfSignedCertificate().certificate

	func test__coversDomains__correctSubsets__returnsTrue() async throws {
		typealias Test = (lhs: Set<String>, rhs: [String])
		let tests: [Test] = [
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
		]
		for (lhs, rhs): Test in tests {
			let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
			let actual = data.covers(domains: rhs)
			XCTAssertTrue(actual)
		}
	}

	func test__coversDomains__incorrectSubsets__returnsFalse() async throws {
		typealias Test = (lhs: Set<String>, rhs: [String])
		let tests: [Test] = [
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
		]
		for (lhs, rhs): Test in tests {
			let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
			let actual = data.covers(domains: rhs)
			XCTAssertFalse(actual)
		}
	}

	func test__coversDomains__includesWildcards__matchesCorrectly() async throws {
		typealias Test = (lhs: Set<String>, rhs: [String], expected: Bool)
		let tests: [Test] = [
			(
				[
					"*.example.com",
				], [
					"foo.example.com",
					"bar.example.com",
				],
				// This is false because we don't want to support wildcards yet
				false
//				true
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
				// This is false because we don't want to support wildcards yet
				false
//				true
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
		]
		for (lhs, rhs, expected): Test in tests {
			let data = CertificateData(domains: lhs, certificate: testCert, isSelfSigned: true)
			let actual = data.covers(domains: rhs)
			XCTAssertEqual(actual, expected, "\(lhs).coversDomains(\(rhs))")
		}
	}
}
