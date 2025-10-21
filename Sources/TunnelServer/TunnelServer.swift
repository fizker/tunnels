public import EnvironmentVariables
import Vapor

public actor TunnelServer {
	let environmentVars: EnvironmentVariables<EnvVar>
	let app: Application

	public init(environmentVars: EnvironmentVariables<EnvVar>) async throws {
		self.environmentVars = environmentVars

		var env = try Environment.detect()
		if env.arguments.count == 1 {
			env.arguments.append("serve")
		}
		if env.arguments[1] == "serve" && !env.arguments.contains("--port") {
			env.arguments.append("--port")
			env.arguments.append("\(environmentVars.port)")
		}

		app = try await Application.make(env)
		try await configure(app, env: environmentVars)
	}

	public func start() async throws {
		try await app.startup()
	}

	public func stop() async throws {
		try await app.asyncShutdown()
	}

	public func waitUntilStopped() async throws {
		try await app.running?.onStop.get()
	}
}
