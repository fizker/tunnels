import DebugServer
import Vapor

let pi = ProcessInfo.processInfo
let port = pi.environment["PORT"] ?? "8113"

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let server = try await DebugServer(port: port)
try await server.start()
try await server.waitUntilStopped()
