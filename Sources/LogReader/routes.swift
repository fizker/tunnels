import Foundation
import Vapor

func routes(_ app: Application) async throws {
	let logController = try await LogController(storagePath: app.environment.storagePath)

	app.get { await logController.summaries(req: $0) }
	app.get(":id") { try await logController.details(req: $0, idParam: "id") }
	app.webSocket("summaries.ws") { req, ws in
		logController.addSummaryListener(webSocket: ws)
	}
}
