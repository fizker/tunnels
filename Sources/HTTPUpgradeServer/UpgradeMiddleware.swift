import Vapor

struct UpgradeMiddleware: AsyncMiddleware {
	var upgradedHost: String
	var upgradedPort: Int?

	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		var url = request.url
		url.scheme = "https"
		url.host = upgradedHost
		url.port = upgradedPort == 443 ? nil : upgradedPort

		return Response(
			status: .temporaryRedirect,
			headers: [
				"location": "\(url)",
			]
		)
	}
}
