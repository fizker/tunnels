import Foundation
import Vapor

struct CatchAllMiddleware: AsyncMiddleware {
	var handler: (Request) -> Response

	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		do {
			return try await next.respond(to: request)
		} catch {
			guard
				let error = error as? any AbortError,
				error.status == .notFound
			else { throw error }

			return handler(request)
		}
	}
}

func routes(_ app: Application) async throws {
	app.middleware.use(CatchAllMiddleware(handler: catchAll(req:)))
	app.middleware.use(LogBodyMiddleware())

	app.get("big-file", use: handleBigFile(req:))
	app.get("heartbeat", use: handleHeartbeat(req:))
	app.get("ping", use: handlePing(req:))
	app.get("redirect", use: handleRedirect(req:))
}
