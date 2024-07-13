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
		var nonCovered = Set(domains).subtracting(self.domains)
		guard !nonCovered.isEmpty
		else { return true }

		for domain in nonCovered {
			var components = domain.split(separator: /\./)
			components[0] = "*"
			let joined = components.joined(separator: ".")
			if self.domains.contains(joined) {
				nonCovered.remove(domain)
			}
		}

		return nonCovered.isEmpty
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

	package init(pemEncoded: String, isSelfSigned: Bool) throws {
		let cert = try Certificate(pemEncoded: pemEncoded)
		try self.init(certificate: cert, isSelfSigned: isSelfSigned)
	}

	package enum CertificateParseError: Error {
		case noDomainsFound
	}
}

package struct CertificateDataArray: Codable {
	/// The certificates.
	package let certificates: [CertificateData]

	/// True if any of the certificates are self-signed.
	package let isSelfSigned: Bool

	/// The list of domains that the certificates covers.
	package let domains: Set<String>

	/// The date that the first certificate expires.
	package let expiresAt: Date

	package init(certificates: [CertificateData]) throws {
		guard !certificates.isEmpty
		else { throw Error.certificateChainCannotBeEmpty }

		self.certificates = certificates
		self.isSelfSigned = certificates.contains(where: \.isSelfSigned)
		self.domains = Set(certificates.flatMap(\.domains))
		self.expiresAt = certificates.map(\.expiresAt).min() ?? .now
	}

	package enum Error: Swift.Error {
		case certificateChainCannotBeEmpty
	}
}
