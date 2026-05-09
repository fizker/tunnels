import Foundation
import Vapor

struct BlacklistMiddleware: SimpleMiddleware, @unchecked Sendable {
	var blacklistedPaths: [Regex<Substring>] = []

	func next(_ request: Request) async throws -> Response? {
		guard try !isBlacklisted(request)
		else { return Response(status: .notFound, body: "Not found") }

		return nil
	}

	func isBlacklisted(_ request: Request) throws -> Bool {
		for pathRegex in blacklistedPaths {
			guard request.url.path.firstMatch(of: pathRegex) == nil
			else { return true }
		}
		return false
	}
}
