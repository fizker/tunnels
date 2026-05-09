import EnvironmentVariables
import RotatingFileLogHandler
import Vapor

package func runServer() async throws {
	let envVar = EnvironmentVariables<EnvVar>(loader: MultiLoader(loaders: [
		.environment,
		DotEnvLoader(location: .path(Environment.get("settings_file") ?? "env-tunnel-server")),
		.default,
	]))

	let acmeFileLogs = try RotatingFileLogHandler(folderPath: "server-logs", filenamePrefix: "acme", rotation: .size(.kilobytes(500)), cleanup: .fileCount(4))
	let otherFileLogs = try RotatingFileLogHandler(folderPath: "server-logs", filenamePrefix: "tunnel-server", rotation: .size(.kilobytes(500)), cleanup: .age(.days(7)))

	LoggingSystem.bootstrap { label in
		var handlers: [any LogHandler] = [
			StreamLogHandler.standardOutput(label: label),
		]
		if isACME(label: label) {
			handlers.append(acmeFileLogs.handler(label: label))
		} else {
			handlers.append(otherFileLogs.handler(label: label))
		}
		return MultiplexLogHandler(handlers)
	}

	let server = try await TunnelServer(environmentVars: envVar)

	try await server.start()
	try await server.waitUntilStopped()
}

nonisolated(unsafe) let acmeCheck = /^acme/.ignoresCase()
func isACME(label: String) -> Bool {
	label.starts(with: acmeCheck)
}
