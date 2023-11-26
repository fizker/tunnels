import Vapor

// configures your application
public func configure(_ app: Application) async throws {
	app.environment = .init(valueGetter: Environment.get(_:))
	try app.environment.assertKeys()

	app.middleware.use(CORSMiddleware())

	try await routes(app)
}
