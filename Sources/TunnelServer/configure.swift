import ACME
import Common
import EnvironmentVariables
import HTTPUpgradeServer
import Vapor
import WebURL

enum ConfigurationError: Error {
	case invalidDatabaseURL(String)
}

// configures your application
func configure(_ app: Application, env: EnvironmentVariables<EnvVar>) async throws {
	app.http.server.configuration.hostname = "0.0.0.0"

	app.environment = env

	app.userStore = try .init(storagePath: try app.environment.userStoragePath)

	if app.environment.useSSL {
		let setup = ACMESetup(
			host: app.environment.host,
			endpoint: try app.environment.acmeEndpoint,
			contactEmail: try app.environment.acmeContactEmail,
			storagePath: try app.environment.acmeStoragePath
		)

		let challengeHandler = ChallengeHandler(host: setup.host)
		app.acmeHandler = try .init(setup: setup, challengeHandler: challengeHandler) {
			do {
				try add(certificates: $0, to: app)
			} catch {
				print("Failed to add certificates to Vapor App: \(error)")
			}
		}
		await app.acmeHandler?.register(endpoints: app.userStore.users().flatMap(\.knownHosts).map(\.value))

		let acmeController = try ACMEController(setup: setup)
		try await acmeController.addCertificate(to: app)

		if let httpPort = app.environment.httpPort {
			let upgradeServer = UpgradeServer(port: httpPort) {
				$0.hasSuffix(app.environment.host) ? .accepted(port: env.port) : .rejected
			}

			await challengeHandler.addTokenChallengeRoute(upgradeServer.app.routes)

			#warning("TODO: These endpoints should only be enabled in debug mode")
			await upgradeServer.app.routes.group(".well-known") {
				$0.post("register-challenge") { req in
					let challenge = try req.content.decode(PendingChallenge.self)
					try await challengeHandler.register(challenge: challenge)
					await challengeHandler.remove(challenge: challenge)
					return "was received"
				}
			}
			try await upgradeServer.start(topLevelApplication: app)

			await challengeHandler.enable()
		}

		await app.acmeHandler?.register(endpoint: setup.host)
	}

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
