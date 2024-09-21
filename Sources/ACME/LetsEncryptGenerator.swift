@preconcurrency import AcmeSwift
import X509

/// Generates certificates via LetsEncrypt using HTTP validations.
actor LetsEncryptGenerator {
	let domains: Set<String>
	let acme: AcmeSwift
	private var order: AcmeOrderInfo?

	init(domains: Set<String>, endpoint: AcmeEndpoint) async throws {
		guard !domains.contains(where: { $0.contains("*") })
		else { throw Error.wildcardDomainsNotSupported }

		self.domains = domains
		self.acme = try await AcmeSwift(acmeEndpoint: endpoint)
	}

	deinit {
		try? acme.syncShutdown()
	}

	/// Creates a set of pending challenges for the requested domains.
	///
	/// - parameter setup: The ACME setup that should be used when talking to LetsEncrypt.
	/// - parameter accountKey: The private key associated with the account.
	/// - returns: A list of pending challenges. These needs to be registered with a HTTP server before the next step is initiated.
	func createPendingChallenges(setup: ACMESetup, accountKey: String) async throws -> [PendingChallenge] {
		let credentials = try AccountCredentials(contacts: [setup.contactEmail], pemKey: accountKey)
		try acme.account.use(credentials)

		let order = try await acme.orders.create(domains: Array(domains))
		self.order = order

		let pendingChallenges = try await acme.orders.describePendingChallenges(from: order, preferring: .http)
		return try pendingChallenges.map {
			switch $0.type {
			case .http:
				return PendingChallenge(endpoint: $0.endpoint, value: $0.value)
			case .dns:
				throw Error.unsupportedChallengeType
			case .alpn:
				throw Error.unsupportedChallengeType
			}
		}
	}

	/// Informs LetsEncrypt that the challenges have been set up and the validation can start.
	/// - throws: ``Error\.orderNotCreated`` if the ``createPendingChallenges(setup:accountKey:)`` function was not called first.
	func validateChallenges() async throws {
		guard let order
		else { throw Error.orderNotCreated }

		try await acme.orders.validateChallenges(from: order, preferring: .http)
	}

	/// Finalizes the order post-validation and returns a list of certificates.
	///
	/// - parameter privateKey: The private key to use for the certificates.
	/// - parameter primaryDomain: The primary domain to use for the certificates.
	func finalize(privateKey: Certificate.PrivateKey, primaryDomain: String) async throws -> CertificateDataArray {
		guard let order
		else { throw Error.orderNotCreated }

		// Let's create a private key and CSR using the rudimentary feature provided by AcmeSwift
		// If the validation didn't throw any error, we can now send our Certificate Signing Request...
		let (_, finalized) = try await acme.orders.finalizeWithRsa(order: order, privateKey: privateKey, subject: primaryDomain, domains: Array(domains))

		// ... and the certificate is ready to download!
		let certs = try await acme.certificates.download(for: finalized)

		return try CertificateDataArray(certificates: try certs.map {
			return try CertificateData(pemEncoded: $0, isSelfSigned: false)
		})
	}

	enum Error: Swift.Error {
		/// We do not support generating LetsEncrypt certificates containing wildcards, because they cannot be validated over HTTP.
		case wildcardDomainsNotSupported
		case unsupportedChallengeType
		case orderNotCreated
	}
}
