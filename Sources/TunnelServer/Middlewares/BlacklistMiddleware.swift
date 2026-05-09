import Logging
import Vapor

struct BlacklistMiddleware: SimpleMiddleware, @unchecked Sendable {
	let logger = Logger(label: "blacklist")
	var blacklistedPaths: [Regex<Substring>] = []

	func next(_ request: Request) async throws -> Response? {
		guard try !isBlacklisted(request)
		else {
			var metadata: Logger.Metadata = [:]
			if let ra = request.remoteAddress {
				metadata["remote"] = .string(ra.description)
			}
			logger.info("\(request.method) \(request.url)", metadata: metadata)
			return Response(status: .notFound, body: "Not found")
		}

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
