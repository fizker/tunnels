import EnvironmentVariables
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
	app.environment = .init(loader: MultiLoader(loaders: [
		.environment,
		DotEnvLoader(location: .path(Environment.get("settings_file") ?? "env-tunnel-logs")),
		.default,
	]))
	try app.environment.assertKeys()

	app.middleware.use(CORSMiddleware())

	try await routes(app)
}
