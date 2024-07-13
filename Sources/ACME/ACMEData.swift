import AcmeSwift
import Foundation
import NIOSSL
import X509

/// Top-level container for the data produced by communication to the LetsEncrypt ACME service.
///
/// It is also used to store the certificates produced by LetsEncrypt.
package struct ACMEData: Codable {
	package var endpoint: AcmeEndpoint
	package var accountKey: String?
	package var certificates: CertWrapper?

	package init(endpoint: AcmeEndpoint, accountKey: String? = nil, certificates: CertWrapper? = nil) {
		self.endpoint = endpoint
		self.accountKey = accountKey
		self.certificates = certificates
	}

	/// Wrapper around a set of certificates and the private key used to create them.
	package struct CertWrapper: Codable {
		/// The certificates.
		package var certificates: CertificateDataArray
		/// The private key used to create the certificates.
		package var privateKey: Certificate.PrivateKey

		package init(certificates: CertificateDataArray, privateKey: Certificate.PrivateKey) {
			self.certificates = certificates
			self.privateKey = privateKey
		}

		/// The date that the first certificate expires.
		package var expiresAt: Date { certificates.expiresAt }
	}
}

extension ACMEData.CertWrapper {
	/// Returns the certificates as `NIOSSLCertificate`, which Vapor requires for its TLS configuration.
	package var nioCertificates: [NIOSSLCertificate] {
		get throws {
			try certificates.certificates.map {
				try NIOSSLCertificate(certificate: $0.certificate)
			}
		}
	}

	/// Returns the private key as a `NIOSSLPrivateKey`, which Vapor requires for its TLS configuration.
	package var nioPrivateKey: NIOSSLPrivateKey {
		get throws {
			try .init(privateKey: privateKey)
		}
	}
}
