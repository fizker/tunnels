import AcmeSwift
import Vapor
import SwiftASN1
import NIOSSL

private let _1Day: TimeInterval = 84_600
private let _30Days = _1Day * 30

class ACMEController {
	enum Error: Swift.Error, CustomStringConvertible {
		case pendingChallenges([ChallengeDescription])
		case validationFailed([AcmeAuthorization.Challenge])
		case differentEndpointInStoredData(AcmeEndpoint)

		var description: String {
			switch self {
			case let .pendingChallenges(challenges):
				"""
				Pending challenges:

				\(challenges.map { "• \($0)" }.joined(separator: "\n"))
				"""
			case let .validationFailed(challenges):
				"""
				Validation failed:

				\(challenges.map { "• \($0)" }.joined(separator: "\n"))
				"""
			case let .differentEndpointInStoredData(endpoint):
				"The stored data was initialized with the \(endpoint) endpoint"
			}
		}
	}

	private let host: String
	private let contactEmail: String
	private let storagePath: String

	private var acmeData: ACMEData

	struct ACMEData: Codable {
		var endpoint: AcmeEndpoint
		var accountKey: String?
		var certificate: CertificateData?
	}

	struct CertificateData: Codable {
		enum Error: Swift.Error {
			case certificateChainCannotBeEmpty
		}

		var certificateChain: [Certificate]
		var privateKeyPEM: String
		var expiresAt: Date

		var createdAt: Date

		init(certificateChain: [Certificate], privateKeyPEM: String, expiresAt: Date, createdAt: Date = .now) throws {
			guard !certificateChain.isEmpty
			else { throw Error.certificateChainCannotBeEmpty }

			self.certificateChain = certificateChain
			self.privateKeyPEM = privateKeyPEM
			self.expiresAt = expiresAt
			self.createdAt = createdAt
		}

		init(certificateChain: [Certificate], privateKey: PEMDocument, createdAt: Date = .now) throws {
			try self.init(certificateChain: certificateChain, privateKeyPEM: privateKey.pemString, createdAt: createdAt)
		}

		init(certificateChain: [Certificate], privateKeyPEM: String, createdAt: Date = .now) throws {
			self.certificateChain = certificateChain
			self.privateKeyPEM = privateKeyPEM
			self.createdAt = createdAt

			guard let firstExpiration = certificateChain.map(\.expirationDate).min()
			else { throw Error.certificateChainCannotBeEmpty }

			self.expiresAt = firstExpiration
		}
	}

	init(host: String, acmeEndpoint: AcmeEndpoint, contactEmail: String, storagePath: String) throws {
		self.contactEmail = contactEmail
		self.host = host
		self.storagePath = storagePath

		let fm = FileManager.default
		if let data = fm.contents(atPath: storagePath) {
			acmeData = try decode(data)

			guard acmeEndpoint == acmeData.endpoint
			else { throw Error.differentEndpointInStoredData(acmeData.endpoint) }
		} else {
			acmeData = .init(endpoint: acmeEndpoint)
		}
	}

	private func lazyLoadData() async throws -> CertificateData {
		if let certificate = acmeData.certificate {
			let untilExpiration = certificate.expiresAt.timeIntervalSince(.now)

			guard untilExpiration < _1Day
			else {
				if untilExpiration < _30Days {
					print("Notice: Certificate expires at \(certificate.expiresAt.formatted())")
				}

				return certificate
			}

			print("Certificate is expired. Renewal initiated")
		}

		return try await requestNewCertificate()
	}

	func addCertificate(to app: Application) async throws {
		let certificate = try await lazyLoadData()

		let certificateChain = try certificate.certificateChain.map {
			let cert = try NIOSSLCertificate(bytes: Array($0.data), format: $0.format.asNIO)
			return NIOSSLCertificateSource.certificate(cert)
		}

		app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
			certificateChain: certificateChain,
			privateKey: .privateKey(try .init(bytes: Array(certificate.privateKeyPEM.utf8), format: .pem))
		)
	}

	private func loadAccount(acme: AcmeSwift) async throws {
		if let accountKey = acmeData.accountKey {
			let credentials = try AccountCredentials(contacts: [contactEmail], pemKey: accountKey)
			try acme.account.use(credentials)
		} else {
			let account = try await acme.account.create(contacts: [contactEmail], acceptTOS: true)
			try acme.account.use(account)
			acmeData.accountKey = account.privateKeyPem!
			try save()
		}
	}

	/// Requests a new certificate from Let's Encrypt
	private func requestNewCertificate() async throws -> CertificateData {
		// Create the client and load Let's Encrypt credentials
		let acme = try await AcmeSwift(acmeEndpoint: acmeData.endpoint)
		defer { try? acme.syncShutdown() }

		try await loadAccount(acme: acme)

		let domains: [String] = ["*.\(host)", host]

		// Create a certificate order for *.ponies.com
		let order = try await acme.orders.create(domains: domains)

		// ... after that, now we can fetch the challenges we need to complete
		let pendingChallenges = try await acme.orders.describePendingChallenges(from: order, preferring: .dns)

		if !pendingChallenges.isEmpty {
			let e = Error.pendingChallenges(pendingChallenges)
			awaitKeyboardInput(message: e.description + "\n")
		}

		while true {
			// Assuming the challenges have been published, we can now ask Let's Encrypt to validate them.
			// If some challenges fail to validate, it is safe to call validateChallenges() again after fixing the underlying issue.
			let failed = try await acme.orders.validateChallenges(from: order, preferring: .dns)

			guard failed.isEmpty
			else {
				let e = Error.validationFailed(failed)
				awaitKeyboardInput(message: e.description + "\n")
				continue
			}

			break
		}

		print("No challenges remaining. Finalizing order.")

		// Let's create a private key and CSR using the rudimentary feature provided by AcmeSwift
		// If the validation didn't throw any error, we can now send our Certificate Signing Request...
		let (privateKey, csr, finalized) = try await acme.orders.finalizeWithRsa(order: order, domains: domains)

		// ... and the certificate is ready to download!
		let certs = try await acme.certificates.download(for: finalized)

		let data = try CertificateData(
			certificateChain: try certs.map(Certificate.init(pemString:)),
			privateKey: try privateKey.serializeAsPEM()
		)
		acmeData.certificate = data
		try save()

		return data
	}

	private func awaitKeyboardInput(message: String? = nil) {
		if let message {
			print(message)
		}
		print("Press enter to continue")
		_ = readLine()
	}

	private func save() throws {
		let data = try encode(acmeData)
		try data.write(to: URL(filePath: storagePath))
	}
}

extension ChallengeDescription: CustomStringConvertible {
	public var description: String {
		switch type {
		case .http:
			"The URL \(endpoint) needs to return \(value)"
		case .dns:
			"Create the following DNS record: \(endpoint) TXT \(value)"
		case .alpn:
			"TLS-ALPN-01 challenge. Endpoint: \(endpoint), value: \(value)"
		}
	}
}

extension AcmeAuthorization.Challenge: CustomStringConvertible {
	public var description: String {
		"\(type): Token=\(token), error=\(error?.localizedDescription ?? "no error"), status=\(status)"
	}
}

func encode(_ value: some Encodable) throws -> Data {
	let encoder = JSONEncoder()
	encoder.outputFormatting = [
		.prettyPrinted,
		.sortedKeys,
	]
	encoder.dateEncodingStrategy = .iso8601
	encoder.dataEncodingStrategy = .base64

	return try encoder.encode(value)
}

func decode<T: Decodable>(_ data: Data) throws -> T {
	let decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .iso8601
	decoder.dataDecodingStrategy = .base64

	return try decoder.decode(T.self, from: data)
}

struct Certificate: Codable {
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
