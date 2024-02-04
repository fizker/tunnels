import Vapor

package func configure(_ app: Application) async throws {
	app.http.server.configuration.hostname = "0.0.0.0"

	app.middleware.use(CORSMiddleware())

	try await routes(app)
}
