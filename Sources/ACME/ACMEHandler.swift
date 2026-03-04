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
	package var acmeData: ACMEData
	let coder = clientCoder
	package let setup: Setup
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
	}

	/// Registers the given endpoint for certificate generation.
	package func register(endpoint: String) {
		register(endpoints: [endpoint])
	}

	/// Registers the given endpoints for certificate generation.
	package func register(endpoints: [String]) {
		registeredEndpoints.formUnion(endpoints)
	}

	private func setRenewalTimer(for date: Date, callCount: Int = 0) {
		guard callCount < 5
		else {
			logger.error("Renewal timer failed too many times")
			// If we fail 5 times in a row, we just execute this immediately.
			// Note that the only thing that can fail to get here is the `Task.sleep()`
			resolveCertificates()
			return
		}

		let logger = logger

		let delay = max(0, date.timeIntervalSinceNow)
		logger.info("Waiting for \(Int(delay)) seconds before performing automatic ACME renewal check")
		Task.detached { [weak self] in
			do {
				try await Task.sleep(for: .seconds(delay))
				logger.info("Performing automatic ACME renewal check")
				await self?.resolveCertificates()
			} catch {
				logger.error("Automatic renewal check failed: \(error)")
				// If the task fails, we just reschedule and try again
				await self?.setRenewalTimer(for: date, callCount: callCount + 1)
			}
		}
	}

	/// Resolves the certificates for the current set of registered endpoints. This will eventually result in calling the
	/// ``OnCertificatesUpdated`` function registered during ``init(setup:challengeHandler:onCertificatesUpdated:)``.
	package func resolveCertificates() {
		if let cert = acmeData.certificate {
			onCertificatesUpdated(cert)
		}

		guard setup.fetchCertificates
		else { return }

		let registeredEndpoints = registeredEndpoints

		logger.info("Requesting new certificate")
		let logger = logger

		Task.detached {
			do {
				let renewalTestDate = try await self.requestCerts(domains: registeredEndpoints)
				await self.setRenewalTimer(for: renewalTestDate)
			} catch {
				logger.error("Failed to create certificates: \(error)")
			}
		}
	}

	private func requestCerts(domains: Set<String>) async throws -> Date {
		try await requestCerts(domains: domains.map { try Domain($0).unwrap() })
	}

	private func requestCerts(domains: [Domain]) async throws -> Date {
		logger.info("Requesting cert for domains: \(domains)")
		let account: Account
		if let a = acmeData.account {
			account = a
		} else {
			logger.info("Creating account")
			let api = try await API(directory: acmeData.directory)
			account = try await api.createAccount(
				request: .init(
					contact: setup.contactEmail,
					termsOfServiceAgreed: true,
				)
			)
			acmeData.account = account
			logger.info("Account created")
		}

		let client = try await ACMEClient(directory: acmeData.directory, account: account)
		logger.info("ACMEClient created")

		let challengeHandler = challengeHandler
		let handlerToken = challengeHandler.createToken()

		let (renewalInfo, cert) = try await client.requestCertificate(covering: domains, renewing: acmeData.certificate) { auths in
			var verifications: [Verification] = []
			for auth in auths {
				let verification = try await challengeHandler.register(auth: auth, token: handlerToken)
				verifications.append(verification)
			}
			try await challengeHandler.handleNonAutomaticSetup(token: handlerToken)
			return verifications
		}

		if let cert {
			logger.info("New certificate received")
			acmeData.certificate = cert

			await challengeHandler.reset(token: handlerToken)

			try save()

			onCertificatesUpdated(cert)
		} else {
			logger.info("No certificate update needed")
		}

		return renewalInfo.recommendedDateForNextCheck
	}

	private func save() throws {
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
	}
}
