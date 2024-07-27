import TunnelServer
import Vapor

let pi = ProcessInfo.processInfo
let port = pi.environment["PORT"] ?? "8110"

var env = try Environment.detect()
if env.arguments.count == 1 {
	env.arguments.append("serve")
}
if env.arguments[1] == "serve" && !env.arguments.contains("--port") {
	env.arguments.append("--port")
	env.arguments.append(port)
}

LoggingSystem.bootstrap { label in
	StreamLogHandler.standardOutput(label: label)
}

let app = try await Application.make(env)
defer { Task {
	try await app.asyncShutdown()
} }

try await configure(app, port: Int(port)!)
try await app.execute()
