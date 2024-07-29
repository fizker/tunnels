import EnvironmentVariables
import Vapor

package func runServer() async throws {
	let envVar = EnvironmentVariables<EnvVar>(loader: MultiLoader(loaders: [
		.environment,
		DotEnvLoader(location: .path(Environment.get("settings_file") ?? "env-tunnel-server")),
		.default,
	]))

	var env = try Environment.detect()
	if env.arguments.count == 1 {
		env.arguments.append("serve")
	}
	if env.arguments[1] == "serve" && !env.arguments.contains("--port") {
		env.arguments.append("--port")
		env.arguments.append("\(envVar.port)")
	}

	LoggingSystem.bootstrap { label in
		StreamLogHandler.standardOutput(label: label)
	}

	let app = try await Application.make(env)
	defer { Task {
		try await app.asyncShutdown()
	} }

	try await configure(app, env: envVar)
	try await app.execute()
}
