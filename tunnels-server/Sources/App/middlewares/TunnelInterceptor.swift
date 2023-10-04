import Vapor

struct TunnelInterceptor: AsyncMiddleware {
	var ownHost: String
	var controller: TunnelController

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard let host = portlessHost(for: request), host != ownHost
		else { return try await next.respond(to: request) }

		guard let matchingRoute = controller.connectedClients.first(where: { $0.tunnel.host == host })
		else { return Response(status: .notFound) }

		try await matchingRoute.webSocket.send("got request for \(request.url)")
		return Response(status: .badGateway)
	}

	private func portlessHost(for request: Request) -> String? {
		request.headers[.host].first?.split(separator: ":").first.map(String.init)
	}
}
