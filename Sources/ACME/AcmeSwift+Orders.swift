import AcmeSwift
import _CryptoExtras
import X509

extension Certificate.PrivateKey {
	static func makeRSA(keySize: _RSA.Signing.KeySize = .bits2048) throws -> Certificate.PrivateKey {
		let p256 = try _CryptoExtras._RSA.Signing.PrivateKey(keySize: .bits2048)
		return Certificate.PrivateKey(p256)
	}
}

extension AcmeSwift.OrdersAPI {
	/// Finalizes an Order and send the RSA CSR.
	/// - Parameters:
	///   - order: The `AcmeOrderInfo` returned by the call to `.create()`
	///   - privateKey: The private key to use for the certificates.
	///   - subject: Subject of certificate. This should be the primary domain
	///   - domains: Domains for certificate
	/// - Throws: Errors that can occur when executing the request.
	/// - Returns: Returns  `Certificate.PrivateKey`, `CertificateSigningRequest` and `Account`.
	func finalizeWithRsa(order: AcmeOrderInfo, privateKey: Certificate.PrivateKey, subject commonName: String, domains: [String]) async throws -> (CertificateSigningRequest, AcmeOrderInfo) {
		guard domains.count > 0
		else { throw AcmeError.noDomains("At least 1 DNS name is required") }

		let name = try DistinguishedName {
			CommonName(commonName)
		}
		let extensions = try Certificate.Extensions {
			SubjectAlternativeNames(domains.map({ GeneralName.dnsName($0) }))
		}
		let extensionRequest = ExtensionRequest(extensions: extensions)
		let attributes = try CertificateSigningRequest.Attributes(
			[.init(extensionRequest)]
		)
		let csr = try CertificateSigningRequest(
			version: .v1,
			subject: name,
			privateKey: privateKey,
			attributes: attributes,
			signatureAlgorithm: .sha256WithRSAEncryption
		)

		let account = try await finalize(order: order, withCsr: csr)

		return (csr, account)
	}
}
