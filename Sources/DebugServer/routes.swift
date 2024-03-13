import CatchAll
import Foundation
import Vapor

func routes(_ app: Application) async throws {
	app.middleware.use(CatchAllMiddleware(handler: catchAll(req:)))
	app.middleware.use(LogBodyMiddleware())

	app.get("big-file", use: handleBigFile(req:))
	app.get("delayed", use: handleDelayedResponse(req:))
	app.get("heartbeat", use: handleHeartbeat(req:))
	app.get("ping", use: handlePing(req:))
	app.get("redirect", use: handleRedirect(req:))
	app.on(.POST, "upload", body: .stream, use: handleReceivingFile(req:))
}
