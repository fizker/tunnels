import EnvironmentVariables
import Vapor

package func runServer() async throws {
	let envVar = EnvironmentVariables<EnvVar>(loader: MultiLoader(loaders: [
		.environment,
		DotEnvLoader(location: .path(Environment.get("settings_file") ?? "env-tunnel-server")),
		.default,
	]))

	LoggingSystem.bootstrap { label in
		StreamLogHandler.standardOutput(label: label)
	}

	let server = try await TunnelServer(environmentVars: envVar)

	try await server.start()
	try await server.waitUntilStopped()
}
