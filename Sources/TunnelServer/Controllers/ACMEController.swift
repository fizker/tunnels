import AcmeSwift
import Vapor
import SwiftASN1
import NIOSSL

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
		var certificateChain: [Data]
		var privateKey: Data
		var expiresAt: Date

		var createdAt: Date = .now
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
			return certificate
		}

		return try await loadCertificate()
	}

	func addCertificate(to app: Application) async throws {
		let certificate = try await lazyLoadData()

		let certificateChain = try certificate.certificateChain.map {
			let cert = try NIOSSLCertificate(bytes: Array($0), format: .der)
			return NIOSSLCertificateSource.certificate(cert)
		}

		app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
			certificateChain: certificateChain,
			privateKey: .privateKey(try .init(bytes: Array(certificate.privateKey), format: .der))
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

	private func loadCertificate() async throws -> CertificateData {
		// Create the client and load Let's Encrypt credentials
		let acme = try await AcmeSwift(acmeEndpoint: acmeData.endpoint)
		defer { try? acme.syncShutdown() }

		try await loadAccount(acme: acme)

		let domains: [String] = ["*.\(host)", host]

		// Create a certificate order for *.ponies.com
		let order = try await acme.orders.create(domains: domains)

		// ... after that, now we can fetch the challenges we need to complete
		let pendingChallenges = try await acme.orders.describePendingChallenges(from: order, preferring: .dns)

		guard pendingChallenges.isEmpty
		else { throw Error.pendingChallenges(pendingChallenges) }

		// At this point, we could programmatically create the challenge DNS records using our DNS provider's API
//		[.... publish the DNS challenge records ....]


		// Assuming the challenges have been published, we can now ask Let's Encrypt to validate them.
		// If some challenges fail to validate, it is safe to call validateChallenges() again after fixing the underlying issue.
		let failed = try await acme.orders.validateChallenges(from: order, preferring: .dns)
		guard failed.isEmpty
		else { throw Error.validationFailed(failed) }

		// Let's create a private key and CSR using the rudimentary feature provided by AcmeSwift
		// If the validation didn't throw any error, we can now send our Certificate Signing Request...
		let (privateKey, csr, finalized) = try await acme.orders.finalizeWithRsa(order: order, domains: domains)

		// ... and the certificate is ready to download!
		let certs = try await acme.certificates.download(for: finalized)

		#warning("TODO: Pick expiration date from certs and subtract some days")
		let data = CertificateData(
			certificateChain: try certs.map { try Data(PEMDocument(pemString: $0).derBytes) },
			privateKey: Data(try privateKey.serializeAsPEM().derBytes),
			expiresAt: Date(timeIntervalSinceNow: 86_400 * 60)
		)
		acmeData.certificate = data
		try save()

		return data
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
