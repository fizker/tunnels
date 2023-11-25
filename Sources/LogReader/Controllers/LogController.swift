import Vapor
import TunnelClient

class LogController {
	let storage: LogStorage

	init(storagePath: String) throws {
		storage = try LogStorage(storagePath: storagePath)
	}

	func summaries(req: Request) async -> Response {
		Response(
			headers: ["content-type": "text/html"],
			body: """
			<!doctype html>
			Hello world!
			"""
		)
	}
}
