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

	if let setup = try env.acmeSetup {
		app.logger.notice("SSL setup initiated")

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
			#warning("In this case we should register acme-routes on the real server. We should probably always do that?")
		}

		await app.acmeHandler?.resolveCertificates()
	}

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
