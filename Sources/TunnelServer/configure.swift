import Vapor

enum ConfigurationError: Error {
	case invalidDatabaseURL(String)
}

// configures your application
public func configure(_ app: Application) throws {
	app.environment = .init(valueGetter: Environment.get(_:))

	app.middleware.use(CORSMiddleware())

	try routes(app)
}
