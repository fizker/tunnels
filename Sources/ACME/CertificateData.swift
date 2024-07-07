import Foundation
import X509

package struct CertificateData: Codable {
	/// The certificate.
	package let certificate: Certificate

	/// True if the certificate is self-signed.
	package let isSelfSigned: Bool

	/// The list of domains that the certificate covers.
	package let domains: Set<String>

	/// The date that the certificate expires.
	package var expiresAt: Date { certificate.notValidAfter }

	package init(domains: some Sequence<String>, certificate: Certificate, isSelfSigned: Bool) {
		self.domains = .init(domains)
		self.certificate = certificate
		self.isSelfSigned = isSelfSigned
	}

	package func covers(domains: [String]) -> Bool {
		if self.domains.isSuperset(of: domains) {
			return true
		}

		return false
	}
}

extension CertificateData {
	package init(certificate: Certificate, isSelfSigned: Bool) throws {
		let domains = try certificate.extensions.subjectAlternativeNames?.compactMap { altName -> String? in
			switch altName {
			case .otherName(_):
				nil
			case .rfc822Name(_):
				nil
			case let .dnsName(domain):
				domain
			case .x400Address(_):
				nil
			case .directoryName(_):
				nil
			case .ediPartyName(_):
				nil
			case .uniformResourceIdentifier(_):
				nil
			case .ipAddress(_):
				nil
			case .registeredID(_):
				nil
			}
		}

		guard let domains
		else { throw CertificateParseError.noDomainsFound }

		self.init(domains: domains, certificate: certificate, isSelfSigned: isSelfSigned)
	}

	package enum CertificateParseError: Error {
		case noDomainsFound
	}
}
