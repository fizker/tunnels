import ACME
import ACMEClient
import ACMEClientModels
import Foundation
import Vapor
import SwiftASN1
import NIOSSL

private let _1Day: TimeInterval = 84_600
private let _30Days = _1Day * 30

func add(certificates: CertificateAndPrivateKey, to app: Application) throws {
	let certificateChain = try certificates.nioCertificates.map {
		return NIOSSLCertificateSource.certificate($0)
	}

	app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
		certificateChain: certificateChain,
		privateKey: .privateKey(try certificates.nioPrivateKey)
	)
}

class ACMEController {
	typealias Setup = ACMEHandler<ChallengeHandler>.Setup

	private let logger = Logger(label: "ACMEController")

	private let setup: Setup

	private var acmeData: ACMEData

	init(setup: Setup) throws {
		self.setup = setup

		let fm = FileManager.default
		if let data = fm.contents(atPath: setup.storagePath) {
			acmeData = try coder.decode(data)

			guard setup.directory == acmeData.directory
			else { throw Setup.Error.differentDirectoryInStoredData(acmeData.directory) }
		} else {
			acmeData = .init(directory: setup.directory)
		}
	}

	private func lazyLoadData() async throws -> CertificateAndPrivateKey {
		if let certs = acmeData.certificate {
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

		try add(certificates: certificates, to: app)
	}

	private func loadAccount() async throws -> Account {
		if let account = acmeData.account {
			return account
		}

		logger.notice("Creating account")
		let api = try await API(directory: acmeData.directory)

		let account = try await api.createAccount(
			request: .init(
				contact: [URL(string: setup.contactEmail).unwrap()],
				termsOfServiceAgreed: true,
			)
		)
		logger.notice("account created")
		acmeData.account = account
		try save()
		return account
	}

	/// Requests a new certificate from Let's Encrypt
	private func requestNewCertificate() async throws -> CertificateAndPrivateKey {
		logger.notice("requestNewCertificate()")
		let account = try await loadAccount()

		let client = try await ACMEClient(
			directory: acmeData.directory,
			account: account,
		)

		logger.notice("Client initialized")

		let domains = try [
			Domain("*.\(setup.host)").unwrap(),
			Domain(setup.host).unwrap(),
		]

		let cert = try await client.requestCertificate(
			covering: domains,
			authHandler: client.handleDNSChallengesViaCLI(_:),
		)

		logger.notice("Certificate request completed")

		acmeData.certificate = cert
		try save()

		logger.notice("Data is saved")

		return cert
	}

	private func awaitKeyboardInput(message: String? = nil) {
		if let message {
			print(message)
		}
		print("Press enter to continue")
		_ = readLine()
	}

	private func save() throws {
		logger.notice("Saving data")
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
		logger.notice("Data saved")
	}
}
