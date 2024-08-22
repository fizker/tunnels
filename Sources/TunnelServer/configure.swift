import ACME
import EnvironmentVariables
import HTTPUpgradeServer
import Vapor

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
		app.acmeHandler = try .init(setup: setup)
		await app.acmeHandler?.register(endpoints: app.userStore.users().flatMap(\.knownHosts).map(\.value))

		let acmeController = try ACMEController(setup: setup)
		try await acmeController.addCertificate(to: app)

		if let httpPort = app.environment.httpPort {
			let upgradeServer = UpgradeServer(port: httpPort) {
				$0.hasSuffix(app.environment.host) ? .accepted(port: env.port) : .rejected
			}

			await upgradeServer.app.routes.group(".well-known") {
				$0.get("debug-test") { req in
					return "hello"
				}
			}
			try await upgradeServer.start(topLevelApplication: app)
		}
	}

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
