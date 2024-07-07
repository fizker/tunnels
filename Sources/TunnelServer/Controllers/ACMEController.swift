import ACME
import AcmeSwift
import Common
import Vapor
import SwiftASN1
import NIOSSL

private let _1Day: TimeInterval = 84_600
private let _30Days = _1Day * 30

class ACMEController {
	enum Error: Swift.Error, CustomStringConvertible {
		case pendingChallenges([ChallengeDescription])
		case validationFailed([AcmeAuthorization.Challenge])

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
			}
		}
	}

	private let setup: Setup
	private let coder = Coder()

	private var acmeData: ACMEData

	init(setup: Setup) throws {
		self.setup = setup

		let fm = FileManager.default
		if let data = fm.contents(atPath: setup.storagePath) {
			acmeData = try coder.decode(data)

			guard setup.endpoint == acmeData.endpoint
			else { throw Setup.Error.differentEndpointInStoredData(acmeData.endpoint) }
		} else {
			acmeData = .init(endpoint: setup.endpoint)
		}
	}

	private func lazyLoadData() async throws -> ACMEData.CertWrapper {
		if let certs = acmeData.certificates {
			let untilExpiration = certs.expiresAt.timeIntervalSince(.now)

			guard untilExpiration < _1Day
			else {
				if untilExpiration < _30Days {
					print("Notice: Certificate expires at \(certs.expiresAt.formatted())")
				}

				return certs
			}

			print("Certificate is expired. Renewal initiated")
		}

		return try await requestNewCertificate()
	}

	func addCertificate(to app: Application) async throws {
		let certificates = try await lazyLoadData()

		let certificateChain = try certificates.nioCertificates.map {
			return NIOSSLCertificateSource.certificate($0)
		}

		app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
			certificateChain: certificateChain,
			privateKey: .privateKey(try certificates.nioPrivateKey)
		)
	}

	private func loadAccount(acme: AcmeSwift) async throws {
		if let accountKey = acmeData.accountKey {
			let credentials = try AccountCredentials(contacts: [setup.contactEmail], pemKey: accountKey)
			try acme.account.use(credentials)
		} else {
			let account = try await acme.account.create(contacts: [setup.contactEmail], acceptTOS: true)
			try acme.account.use(account)
			acmeData.accountKey = account.privateKeyPem!
			try save()
		}
	}

	/// Requests a new certificate from Let's Encrypt
	private func requestNewCertificate() async throws -> ACMEData.CertWrapper {
		// Create the client and load Let's Encrypt credentials
		let acme = try await AcmeSwift(acmeEndpoint: acmeData.endpoint)
		defer { try? acme.syncShutdown() }

		try await loadAccount(acme: acme)

		let domains: [String] = ["*.\(setup.host)", setup.host]

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

		let data = ACMEData.CertWrapper(
			certificates: try CertificateDataArray(certificates: try certs.map {
				return try CertificateData(pemEncoded: $0, isSelfSigned: false)
			}),
			privateKey: privateKey
		)
		acmeData.certificates = data
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
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
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
