import ACME
import ACMEClientModels
import Vapor
import NIOSSL

func add(certificates: CertificateAndPrivateKey, to app: Application) throws {
	let certificateChain = try certificates.nioCertificates.map {
		return NIOSSLCertificateSource.certificate($0)
	}

	app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
		certificateChain: certificateChain,
		privateKey: .privateKey(try certificates.nioPrivateKey)
	)
}
