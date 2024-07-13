import ACME
import NIOSSL
import SwiftASN1
import X509

func convert(oldData: OldACMEData, oldCert: OldCertificateData) throws -> ACMEData {
	let certificates = try CertificateDataArray(certificates: oldCert.certificateChain.map {
		let pemDoc: PEMDocument
		switch $0.format {
		case .pem:
			guard let str = String(data: $0.data, encoding: .utf8)
			else { throw ConvertError.invalidPEMFormat }
			pemDoc = try PEMDocument(pemString: str)
		case .der:
			pemDoc = PEMDocument(type: Certificate.defaultPEMDiscriminator, derBytes: Array($0.data))
		}
		let certificate = try Certificate(pemDocument: pemDoc)
		return try CertificateData(certificate: certificate, isSelfSigned: false)
	})

	return ACMEData(
		endpoint: oldData.endpoint,
		accountKey: oldData.accountKey,
		certificates: ACMEData.CertWrapper(
			certificates: certificates,
			privateKey: try .init(pemEncoded: oldCert.privateKeyPEM)
		)
	)
}

enum ConvertError: Error {
	case invalidPEMFormat
}
