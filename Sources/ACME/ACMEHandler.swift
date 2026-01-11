package import ACMEClient
package import ACMEClientModels
import Foundation
import FzkExtensions
import Logging

package protocol EndpointChallengeHandler: Sendable {
	associatedtype Token: Sendable

	func createToken() -> Token
	func register(auth: TypedAuthorization, token: Token) async throws -> Verification
	func handleNonAutomaticSetup(token: Token) async throws
	func reset(token: Token) async
}

package actor ACMEHandler<ChallengeHandler: EndpointChallengeHandler> {
	package typealias Setup = ACMESetup
	package typealias OnCertificatesUpdated = (CertificateAndPrivateKey) -> Void

	var registeredEndpoints: Set<String> = []
	var acmeData: ACMEData
	let coder = Coder()
	let setup: Setup
	let challengeHandler: ChallengeHandler
	let logger = Logger(label: "ACMEHandler")
	let onCertificatesUpdated: OnCertificatesUpdated

	package init(setup: Setup, challengeHandler: ChallengeHandler, onCertificatesUpdated: @escaping OnCertificatesUpdated) throws {
		self.setup = setup
		self.challengeHandler = challengeHandler
		self.onCertificatesUpdated = onCertificatesUpdated

		let fm = FileManager.default
		if let data = fm.contents(atPath: setup.storagePath) {
			acmeData = try coder.decode(data)

			guard setup.directory == acmeData.directory
			else { throw Setup.Error.differentDirectoryInStoredData(acmeData.directory) }
		} else {
			acmeData = .init(directory: setup.directory)
		}

		#warning("TODO: Check if the certificate is ready for renewal and set up timer for when it needs renewal")
	}

	/// Registers the given endpoint for certificate generation.
	package func register(endpoint: String) {
		register(endpoints: [endpoint])
	}

	/// Registers the given endpoints for certificate generation.
	package func register(endpoints: [String]) {
		registeredEndpoints.formUnion(endpoints)
	}

	/// Resolves the certificates for the current set of registered endpoints. This will eventually result in calling the
	/// ``OnCertificatesUpdated`` function registered during ``init(setup:challengeHandler:onCertificatesUpdated:)``.
	package func resolveCertificates() {
		if let cert = acmeData.certificate {
			onCertificatesUpdated(cert)
		}

		let endpoints = Array(registeredEndpoints)
		let uncoveredEndpoints: Set<String>
		if let cert = acmeData.certificate {
			if !cert.covers(domains: endpoints) {
				uncoveredEndpoints = endpoints.filter { !cert.covers(domains: [$0]) }
					|> Set.init
			} else {
				uncoveredEndpoints = []
			}
		} else {
			uncoveredEndpoints = Set(endpoints)
		}

		guard !uncoveredEndpoints.isEmpty
		else { return }

		logger.info("Requesting new certificate")
		let logger = logger

		Task.detached {
			do {
				try await self.requestCerts(domains: uncoveredEndpoints)
			} catch {
				logger.error("Failed to create certificates: \(error)")
			}
		}
	}

	private func requestCerts(domains: Set<String>) async throws {
		try await requestCerts(domains: domains.map { try Domain($0).unwrap() })
	}

	private func requestCerts(domains: [Domain]) async throws {
		let account: Account
		if let a = acmeData.account {
			account = a
		} else {
			let api = try await API(directory: acmeData.directory)
			account = try await api.createAccount(request: .init())
			acmeData.account = account
		}

		let client = try await ACMEClient(directory: acmeData.directory, account: account)

		let challengeHandler = challengeHandler
		let handlerToken = challengeHandler.createToken()

		let cert = try await client.requestCertificate(covering: domains) { auths in
			var verifications: [Verification] = []
			for auth in auths {
				let verification = try await challengeHandler.register(auth: auth, token: handlerToken)
				verifications.append(verification)
			}
			try await challengeHandler.handleNonAutomaticSetup(token: handlerToken)
			return verifications
		}

		await challengeHandler.reset(token: handlerToken)

		onCertificatesUpdated(cert)
	}

	private func save() throws {
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
	}
}
