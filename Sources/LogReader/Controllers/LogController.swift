import Foundation
import Models
import Vapor
import TunnelClient

actor LogController {
	let storage: LogStorage
	var summaryListeners: [WebSocket] = []

	let responseTimeFormat = FloatingPointFormatStyle<Double>()
		.precision(.fractionLength(2))
		.grouping(.automatic)

	init(storagePath: String) async throws {
		storage = try await LogStorage(storagePath: storagePath)
		try await storage.listenForUpdates { [weak self] summaries in
			await self?.updateSummaries(summaries)
		}
	}

	private func updateSummaries(_ newSummaries: [LogSummary]) {
		for idx in summaryListeners.indices.reversed() {
			let listener = summaryListeners[idx]
			guard !listener.isClosed
			else {
				summaryListeners.remove(at: idx)
				continue
			}
			listener.send(newSummaries.map(map).joined())
		}
	}

	func addSummaryListener(webSocket: WebSocket) {
		summaryListeners.append(webSocket)
	}

	func summaries(req: Request) async -> Response {
		let summaries = await storage.summaries

		return html("""
		<h1>Logs</h1>
		\(summaries.isEmpty
			? "<p>No logs</p>"
			: """
			<table class="hlist">
				<thead>
					<tr>
						<th>Method</th>
						<th>Path</th>
						<th>Status</th>
						<th>Response time</th>
						<th>Host</th>
						<th></th>
					</tr>
				</thead>
				<tbody class="summary-list">
					\(summaries.sorted { $0.responseSent > $1.responseSent }.map(map).joined())
				</tbody>
			</table>
			""")

		\(summaryUpdateCode)
		""")
	}

	func details(req: Request, idParam: String) async throws -> Response {
		let id = try req.parameters.require(idParam, as: Log.ID.self)
		guard let log = await storage.log(id: id)
		else { return .init(status: .notFound) }

		return html("""
		<h1>\(log.request.method) \(log.request.path)</h1>

		<table class="vlist">
			<tr>
				<th>Status:</th>
				<td>\(log.response.status)</td>
			</tr>
			<tr>
				<th>Response time:</th>
				<td>\(log.responseTime.formatted(responseTimeFormat)) ms</td>
			</tr>
		</table>

		<h2>Request</h2>
		<h3>Headers</h3>
		\(map(log.request.headers))

		<h3>Body</h3>
		\(map(log.request.body, contentHeader: log.request.headers.firstHeader(named: "content-type")))

		<h2>Response</h2>
		<h3>Headers</h3>
		\(map(log.response.headers))

		<h3>Body</h3>
		\(map(log.response.body, contentHeader: log.response.headers.firstHeader(named: "content-type")))
		""")
	}

	func map(_ summary: LogSummary) -> String {
		return """
			<tr>
				<td>\(summary.requestMethod)</td>
				<td>\(summary.path)</td>
				<td>\(summary.responseStatus)</td>
				<td style="text-align: right">\(summary.responseTime.formatted(responseTimeFormat)) ms</td>
				<td>\(summary.host)</td>
				<td><a href="/\(summary.id)">Details</a></td>
			</tr>
		"""
	}

	let summaryUpdateCode = """
		<script>
		const socket = new WebSocket("/summaries.ws")
		socket.addEventListener("message", (event) => {
			document.querySelector(".summary-list").innerHTML = event.data
		})
		</script>
		"""

	func map(_ headers: Models.HTTPHeaders) -> String {
		return """
		<table class="vlist">
			\(headers.map{($0, $1)}.sorted{$0.0<$1.0}.map { """
			<tr>
				<th>\($0):</th>
				<td>\($1.joined(separator: "<br>"))</td>
			</tr>
			""" }.joined())
		</table>
		"""
	}

	func map(_ body: Models.HTTPBody?, contentHeader: String?) -> String {
		return switch body {
		case nil: ""
		case let .binary(value): value.description
		case .stream: ""
		case let .text(value): value
		}
	}

	func html(_ body: String) -> Response {
		Response(
			headers: ["content-type": "text/html"],
			body: .init(string: """
			<!doctype html>

			<style>
			.hlist th {
				text-align: left;
			}
			.vlist th {
				text-align: right;
			}
			</style>

			\(body)
			""")
		)
	}
}
