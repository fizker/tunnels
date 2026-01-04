package import ACMEClientModels
package import NIOSSL

extension ACMEClientModels.CertificateData {
	/// Returns the certificate as `NIOSSLCertificate`, which Vapor requires for its TLS configuration.
	package var nioCertificate: NIOSSLCertificate {
		get throws {
			try NIOSSLCertificate(certificate: certificate)
		}
	}
}

extension CertificateChain {
	/// Returns the certificates as `NIOSSLCertificate`, which Vapor requires for its TLS configuration.
	package var nioCertificates: [NIOSSLCertificate] {
		get throws {
			return try certificates.map {
				try $0.nioCertificate
			}
		}
	}
}

extension CertificateAndPrivateKey {
	/// Returns the certificates as `NIOSSLCertificate`, which Vapor requires for its TLS configuration.
	package var nioCertificates: [NIOSSLCertificate] {
		get throws {
			try certificateChain.nioCertificates
		}
	}

	/// Returns the private key as a `NIOSSLPrivateKey`, which Vapor requires for its TLS configuration.
	package var nioPrivateKey: NIOSSLPrivateKey {
		get throws {
			try .init(privateKey: privateKey)
		}
	}
}
