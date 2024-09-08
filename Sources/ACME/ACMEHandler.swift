import AcmeSwift
import Common
import Foundation
import FzkExtensions

package protocol EndpointChallengeHandler: Sendable {
	func register(challenge: PendingChallenge) async throws -> Void
	func remove(challenge: PendingChallenge) async
}

package actor ACMEHandler {
	package typealias Setup = ACMESetup
	package typealias OnCertificatesUpdated = (ACMEData.CertWrapper) -> Void

	var registeredEndpoints: Set<String> = []
	var acmeData: ACMEData
	let coder = Coder()
	let setup: Setup
	let challengeHandler: any EndpointChallengeHandler
	let onCertificatesUpdated: OnCertificatesUpdated

	package init(setup: Setup, challengeHandler: some EndpointChallengeHandler, onCertificatesUpdated: @escaping OnCertificatesUpdated) throws {
		self.setup = setup
		self.challengeHandler = challengeHandler
		self.onCertificatesUpdated = onCertificatesUpdated

		let fm = FileManager.default
		if let data = fm.contents(atPath: setup.storagePath) {
			acmeData = try coder.decode(data)

			guard setup.endpoint == acmeData.endpoint
			else { throw Setup.Error.differentEndpointInStoredData(acmeData.endpoint) }
		} else {
			acmeData = .init(endpoint: setup.endpoint)
		}

		#warning("TODO: Check if the certificate is ready for renewal and set up timer for when it needs renewal")
	}

	/// Registers the given endpoint for certificate generation. This will eventually result in calling the
	/// ``OnCertificatesUpdated`` function registered during ``init(setup:challengeHandler:onCertificatesUpdated:)``.
	package func register(endpoint: String) {
		register(endpoints: [endpoint])
	}

	private var registerTimeToken: Date?

	/// Registers the given endpoints for certificate generation. This will eventually result in calling the
	/// ``OnCertificatesUpdated`` function registered during ``init(setup:challengeHandler:onCertificatesUpdated:)``.
	package func register(endpoints: [String]) {
		registeredEndpoints.formUnion(endpoints)

		if let certs = acmeData.certificates {
			if !certs.covers(domains: endpoints) {
				let uncoveredEndpoints = endpoints.filter { !certs.covers(domains: [$0]) }
					|> Set.init
				print("Updating certificates for \(uncoveredEndpoints)")

				let token = Date.now
				registerTimeToken = token

				Task {
					do {
						try await Task.sleep(for: .seconds(1))
						guard token == registerTimeToken
						else { return }

						let certs = try await requestCerts(domains: uncoveredEndpoints)
						onCertificatesUpdated(certs)
					} catch {
						print("Failed to create certificates: \(error)")
					}
				}
			} else {
				onCertificatesUpdated(certs)
			}
		}
	}

	private struct ChallengeBundle {
		let id = UUID()
		var domains: Set<String>
		var challenges: [PendingChallenge]
	}

	private var currentChallenges: [ChallengeBundle] = []

	private func requestCerts(domains: Set<String>) async throws -> ACMEData.CertWrapper {
		let accountKey: String
		if let ak = acmeData.accountKey {
			accountKey = ak
		} else {
			accountKey = try await generateAccountKey()
		}

		let generator = try await LetsEncryptGenerator(domains: domains, endpoint: setup.endpoint)
		let pendingChallenges = try await generator.createPendingChallenges(setup: setup, accountKey: accountKey)

		let bundle = ChallengeBundle(domains: domains, challenges: pendingChallenges)
		currentChallenges.append(bundle)
		async let challenge = withThrowingTaskGroup(of: Bool.self) { group in
			for c in pendingChallenges {
				group.addTask {
					try await self.challengeHandler.register(challenge: c)
					return true
				}
			}

			try await group.waitForAll()
			return true
		}

		try await generator.validateChallenges()

		_ = try await challenge

		for c in pendingChallenges {
			await challengeHandler.remove(challenge: c)
		}

		let privateKey = try acmeData.certificates?.privateKey ?? .makeRSA()

		let newCerts = try await generator.finalize(privateKey: privateKey, primaryDomain: setup.host)
		let allCerts: ACMEData.CertWrapper
		if var certs = acmeData.certificates {
			certs.certificates = try .init(certificates: certs.certificates.certificates + newCerts.certificates)
			acmeData.certificates = certs
			allCerts = certs
		} else {
			allCerts = .init(certificates: newCerts, privateKey: privateKey)
			acmeData.certificates = allCerts
		}
		return allCerts
	}

	private func generateAccountKey() async throws -> String {
		let setup = self.setup
		let accountKey = try await Task.detached {
			let acme = try await AcmeSwift(acmeEndpoint: setup.endpoint)
			let account = try await acme.account.create(contacts: [setup.contactEmail], acceptTOS: true)
			try acme.account.use(account)
			return account.privateKeyPem!
		}.value
		acmeData.accountKey = accountKey
		return accountKey
	}

	private func save() throws {
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
	}
}
