import Crypto
import Foundation
import X509

struct CertificateGenerator {
	let commonName: String
	let domains: Set<String>

	func generateSelfSignedCertificate() throws -> CertificateData {
		let key = P256.Signing.PrivateKey()

		let subject = try DistinguishedName {
			CommonName(commonName)
		}
		let cert = try Certificate(
			version: .v3,
			serialNumber: .init(),
			publicKey: .init(key.publicKey),
			notValidBefore: .now,
			notValidAfter: Date(timeIntervalSinceNow: 3600 * 24 * 365),
			issuer: subject,
			subject: subject,
			signatureAlgorithm: .ecdsaWithSHA256,
			extensions: try .init(builder: {
				Critical(BasicConstraints.isCertificateAuthority(maxPathLength: nil))
				Critical(KeyUsage(digitalSignature: true, keyCertSign: true))
				SubjectAlternativeNames(domains.map {
					.dnsName($0)
				})
			}),
			issuerPrivateKey: .init(key)
		)

		return CertificateData(domains: domains, certificate: cert, isSelfSigned: true)
	}
}
