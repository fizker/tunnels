import AcmeSwift
import Foundation
import NIOSSL
import SwiftASN1

struct OldACMEData: Codable {
	var endpoint: AcmeEndpoint
	var accountKey: String?
	var certificate: OldCertificateData?
}

struct OldCertificateData: Codable {
	enum Error: Swift.Error {
		case certificateChainCannotBeEmpty
	}

	var certificateChain: [OldCertificate]
	var privateKeyPEM: String
	var expiresAt: Date

	var createdAt: Date

	init(certificateChain: [OldCertificate], privateKeyPEM: String, expiresAt: Date, createdAt: Date = .now) throws {
		guard !certificateChain.isEmpty
		else { throw Error.certificateChainCannotBeEmpty }

		self.certificateChain = certificateChain
		self.privateKeyPEM = privateKeyPEM
		self.expiresAt = expiresAt
		self.createdAt = createdAt
	}

	init(certificateChain: [OldCertificate], privateKey: PEMDocument, createdAt: Date = .now) throws {
		try self.init(certificateChain: certificateChain, privateKeyPEM: privateKey.pemString, createdAt: createdAt)
	}

	init(certificateChain: [OldCertificate], privateKeyPEM: String, createdAt: Date = .now) throws {
		self.certificateChain = certificateChain
		self.privateKeyPEM = privateKeyPEM
		self.createdAt = createdAt

		guard let firstExpiration = certificateChain.map(\.expirationDate).min()
		else { throw Error.certificateChainCannotBeEmpty }

		self.expiresAt = firstExpiration
	}
}

struct OldCertificate: Codable {
	var data: Data
	var expirationDate: Date
	var format: Format

	init(data: Data, format: Format) throws {
		self.data = data
		self.format = format

		let cert = try NIOSSLCertificate(bytes: Array(data), format: format.asNIO)
		expirationDate = Date(timeIntervalSince1970: TimeInterval(cert.notValidAfter))
	}

	init(pemString: String) throws {
		try self.init(pemDocument: try PEMDocument(pemString: pemString))
	}

	init(pemDocument: PEMDocument) throws {
		try self.init(data: Data(pemDocument.derBytes), format: .der)
	}

	enum Format: String, Codable {
		case pem, der

		var asNIO: NIOSSLSerializationFormats {
			switch self {
			case .pem: .pem
			case .der: .der
			}
		}
	}
}
