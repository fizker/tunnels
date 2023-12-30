import HTTPUpgradeServer
import Vapor

enum ConfigurationError: Error {
	case invalidDatabaseURL(String)
}

// configures your application
public func configure(_ app: Application, port: Int) async throws {
	app.http.server.configuration.hostname = "0.0.0.0"

	app.environment = .init(valueGetter: Environment.get(_:))

	if app.environment.useSSL {
		let acmeController = try ACMEController(
			host: app.environment.host,
			acmeEndpoint: try app.environment.acmeEndpoint,
			contactEmail: try app.environment.acmeContactEmail,
			storagePath: try app.environment.acmeStoragePath
		)
		try await acmeController.addCertificate(to: app)

		if let httpPort = app.environment.httpPort {
			let upgradeServer = UpgradeServer(port: httpPort) {
				$0.hasSuffix(app.environment.host) ? .accepted(port: port) : .rejected
			}
			try upgradeServer.start(topLevelApplication: app)
		}
	}

	app.userStore = try .init(storagePath: try app.environment.userStoragePath)

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
