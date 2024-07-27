import EnvironmentVariables
import Vapor

func runServer() async throws {
	var envVars = EnvironmentVariables<EnvVar>(loader: MultiLoader(loaders: [
		.environment,
		DotEnvLoader(location: .path(Environment.get("settings_file") ?? "env-tunnel-logs")),
		.default,
	]))
	try envVars.assertKeys()

	var env = try Environment.detect()
	if env.arguments.count == 1 {
		env.arguments.append("serve")
	}
	if env.arguments[1] == "serve" && !env.arguments.contains("--port") {
		env.arguments.append("--port")
		env.arguments.append("\(envVars.port)")
	}

	try LoggingSystem.bootstrap(from: &env)
	let app = try await Application.make(env)
	defer { Task {
		try await app.asyncShutdown()
	} }

	try await configure(app)
	try await app.execute()
}
