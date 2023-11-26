import Foundation
import Vapor

func routes(_ app: Application) throws {
	let logController = try LogController(storagePath: app.environment.storagePath)

	app.get { await logController.summaries(req: $0) }
	app.get(":id") { try await logController.details(req: $0, idParam: "id") }
}
