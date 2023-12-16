import Vapor

enum ConfigurationError: Error {
	case invalidDatabaseURL(String)
}

// configures your application
public func configure(_ app: Application) async throws {
	app.environment = .init(valueGetter: Environment.get(_:))

	if app.environment.useSSL {
		let acmeController = try ACMEController(
			host: app.environment.host,
			acmeEndpoint: try app.environment.acmeEndpoint,
			contactEmail: try app.environment.acmeContactEmail,
			storagePath: try app.environment.acmeStoragePath
		)
		try await acmeController.addCertificate(to: app)
	}

	app.userStore = .init()

	app.middleware.use(CORSMiddleware())
	app.middleware.use(OAuthErrorMiddleware())

	try routes(app)
}
