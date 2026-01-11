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

	app.userStore = try .init(storagePath: app.environment.userStoragePath)

	if app.environment.useSSL {
		app.logger.notice("SSL setup initiated")
		let setup = ACMESetup(
			host: app.environment.host,
			directory: try app.environment.acmeDirectory,
			contactEmail: try app.environment.acmeContactEmail,
			storagePath: try app.environment.acmeStoragePath,
		)

		let challengeHandler = ChallengeHandler(host: setup.host)
		app.acmeHandler = try .init(setup: setup, challengeHandler: challengeHandler) {
			do {
				try add(certificates: $0, to: app)
			} catch {
				print("Failed to add certificates to Vapor App: \(error)")
			}
		}

		await app.acmeHandler?.register(endpoint: setup.host)
		await app.acmeHandler?.register(endpoints: app.userStore.users().flatMap(\.knownHosts).map(\.value))

		if let httpPort = app.environment.httpPort {
			let upgradeServer = try await UpgradeServer(port: httpPort) {
				$0.hasSuffix(app.environment.host) ? .accepted(port: env.port) : .rejected
			}

			await challengeHandler.addTokenChallengeRoute(upgradeServer.app.routes)

			try await upgradeServer.start(topLevelApplication: app)
		} else {

		}
	}

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
