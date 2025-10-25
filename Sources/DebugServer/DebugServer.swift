import Vapor

public actor DebugServer {
	let app: Application

	public init(port: String) async throws {
		var env = try Environment.detect()
		if env.arguments.count == 1 {
			env.arguments.append("serve")
		}
		if env.arguments[1] == "serve" && !env.arguments.contains("--port") {
			env.arguments.append("--port")
			env.arguments.append(port)
		}

		app = try await Application.make(env)
		try await configure(app)
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
