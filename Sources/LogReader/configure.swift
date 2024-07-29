import EnvironmentVariables
import Vapor

// configures your application
func configure(_ app: Application, env: EnvironmentVariables<EnvVar>) async throws {
	app.environment = env

	app.middleware.use(CORSMiddleware())

	try await routes(app)
}
