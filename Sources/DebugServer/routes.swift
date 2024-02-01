import Foundation
import Vapor

func routes(_ app: Application) async throws {
	app.middleware.use(LogBodyMiddleware())

	app.get("big-file", use: handleBigFile(req:))
	app.get("heartbeat", use: handleHeartbeat(req:))
	app.get("ping", use: handlePing(req:))
	app.get("redirect", use: handleRedirect(req:))
	app.get("**", use: catchAll(req:))
	app.post("**", use: catchAll(req:))
	app.put("**", use: catchAll(req:))
	app.delete("**", use: catchAll(req:))
}
