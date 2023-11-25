import Foundation
import Vapor

func routes(_ app: Application) throws {
	let logController = try LogController(storagePath: app.environment.storagePath)

	app.get { await logController.summaries(req: $0) }
}
