import Vapor

// configures your application
public func configure(_ app: Application) throws {
	app.environment = .init(valueGetter: Environment.get(_:))
	try app.environment.assertKeys()

	app.middleware.use(CORSMiddleware())

	try routes(app)
}
