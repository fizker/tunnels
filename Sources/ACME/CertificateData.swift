import Foundation
import X509

struct CertificateData: Codable {
	/// The certificate.
	let certificate: Certificate

	/// True if the certificate is self-signed.
	let isSelfSigned: Bool

	/// The list of domains that the certificate covers.
	let domains: Set<String>

	/// The date that the certificate expires.
	var expiresAt: Date { certificate.notValidAfter }

	init(domains: some Sequence<String>, certificate: Certificate, isSelfSigned: Bool) {
		self.domains = .init(domains)
		self.certificate = certificate
		self.isSelfSigned = isSelfSigned
	}

	func covers(domains: [String]) -> Bool {
		if self.domains.isSuperset(of: domains) {
			return true
		}

		return false
	}
}
