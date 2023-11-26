import Vapor
import TunnelClient

class LogController {
	let storage: LogStorage

	init(storagePath: String) throws {
		storage = try LogStorage(storagePath: storagePath)
	}

	func summaries(req: Request) async -> Response {
		let summaries = await storage.summaries

		return Response(
			headers: [
				"content-type": "text/html"
			],
			body: .init(string: """
			<!doctype html>

			<h1>Logs</h1>
			\(summaries.isEmpty
				? "<p>No logs</p>"
				: """
				<table>
					<tr>
						<th>Method</th>
						<th>Path</th>
						<th>Status</th>
						<th>Host</th>
					</tr>
					\(summaries.map(map).joined())
				</table>
				"""
			)
			""")
		)
	}

	func map(_ summary: LogSummary) -> String {
		return """
			<tr>
				<td>\(summary.requestMethod)</td>
				<td>\(summary.path)</td>
				<td>\(summary.responseStatus)</td>
				<td>\(summary.host)</td>
			</tr>
		"""
	}
}
