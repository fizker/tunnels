import AcmeSwift
import Vapor
import SwiftASN1
import NIOSSL

class ACMEController {
	enum Error: Swift.Error {
		case validationFailed([AcmeAuthorization.Challenge])
	}

	private let host: String
	private let contactEmail: String
	private var accountKey: String?
	private let acmeEndpoint: AcmeEndpoint

	var certificateChain: [NIOSSLCertificateSource]?
	var privateKey: NIOSSLPrivateKeySource?

	init(host: String, acmeEndpoint: AcmeEndpoint, contactEmail: String, accountKey: String?) {
		self.accountKey = accountKey
		self.acmeEndpoint = acmeEndpoint
		self.contactEmail = contactEmail
		self.host = host
	}

	func addCertificate(to app: Application) async throws {
		let (certificateChain, privateKey) = try loadCertificateData()

		app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
			certificateChain: certificateChain,
			privateKey: privateKey
		)
	}

	private func loadCertificate() async throws {
		// Create the client and load Let's Encrypt credentials
		let acme = try await AcmeSwift(acmeEndpoint: acmeEndpoint)
		if let accountKey {
			let credentials = try AccountCredentials(contacts: [contactEmail], pemKey: accountKey)
			try acme.account.use(credentials)
		} else {
			let account = try await acme.account.create(contacts: [contactEmail], acceptTOS: true)
			accountKey = account.privateKeyPem
		}

		let domains: [String] = ["*.\(host)", host]

		// Create a certificate order for *.ponies.com
		let order = try await acme.orders.create(domains: domains)

		// ... after that, now we can fetch the challenges we need to complete
		let pendingChallenges = try await acme.orders.describePendingChallenges(from: order, preferring: .dns)

		for desc in pendingChallenges {
			if desc.type == .http {
				print("\n • The URL \(desc.endpoint) needs to return \(desc.value)")
			}
			else if desc.type == .dns {
				print("\n • Create the following DNS record: \(desc.endpoint) TXT \(desc.value)")
			}
		}

		// At this point, we could programmatically create the challenge DNS records using our DNS provider's API
//		[.... publish the DNS challenge records ....]


		// Assuming the challenges have been published, we can now ask Let's Encrypt to validate them.
		// If some challenges fail to validate, it is safe to call validateChallenges() again after fixing the underlying issue.
		let failed = try await acme.orders.validateChallenges(from: order, preferring: .dns)
		guard failed.count == 0
		else {
			throw Error.validationFailed(failed)
		}

		// Let's create a private key and CSR using the rudimentary feature provided by AcmeSwift
		// If the validation didn't throw any error, we can now send our Certificate Signing Request...
		let (privateKey, csr, finalized) = try await acme.orders.finalizeWithRsa(order: order, domains: domains)

		// ... and the certificate is ready to download!
		let certs = try await acme.certificates.download(for: finalized)

		try saveCertificateData(
			certificateChain: try certs.map {
				let pem = try PEMDocument(pemString: $0)
				let cert = try NIOSSLCertificate(bytes: pem.derBytes, format: .der)
				return .certificate(cert)
			},
			privateKey: try .privateKey(.init(bytes: privateKey.serializeAsPEM().derBytes, format: .der))
		)
	}

	private func loadCertificateData() throws -> (certificateChain: [NIOSSLCertificateSource], privateKey: NIOSSLPrivateKeySource) {
		if let certificateChain, let privateKey {
			return (certificateChain, privateKey)
		}
	}

	private func saveCertificateData(certificateChain: [NIOSSLCertificateSource], privateKey: NIOSSLPrivateKeySource) throws {
		self.certificateChain = certificateChain
		self.privateKey = privateKey
	}
}
