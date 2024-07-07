import NIOSSL
import X509

extension NIOSSLCertificate {
	package convenience init(certificate: X509.Certificate) throws {
		let pemDoc = try certificate.serializeAsPEM()
		try self.init(bytes: pemDoc.derBytes, format: .der)
	}
}

extension NIOSSLPrivateKey {
	package convenience init(privateKey: X509.Certificate.PrivateKey) throws {
		let pemDoc = try privateKey.serializeAsPEM()
		try self.init(bytes: pemDoc.derBytes, format: .der)
	}
}
