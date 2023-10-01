import Vapor

enum ConfigurationError: Error {
	case invalidDatabaseURL(String)
}

// configures your application
public func configure(_ app: Application) throws {
	app.middleware.use(CORSMiddleware())

	try routes(app)
}
