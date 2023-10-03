import Vapor

struct TunnelInterceptor: AsyncMiddleware {
	var ownHost: String
	var controller: TunnelController

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard let host = portlessHost(for: request), host != ownHost
		else { return try await next.respond(to: request) }

		let matchingRoute = controller.tunnels.values.first { $0.host == host }

		request.logger.info("""
		Tunnelling for \(host) to \(request.method) \(request.url) to \(matchingRoute == nil ? "nothing" : "detected route")
		""")

		return Response(status: matchingRoute == nil ? .notFound : .badGateway)
	}

	private func portlessHost(for request: Request) -> String? {
		request.headers[.host].first?.split(separator: ":").first.map(String.init)
	}
}
