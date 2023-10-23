import Models
import Vapor

struct TunnelInterceptor: AsyncMiddleware {
	var ownHost: String
	var controller: TunnelController

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard let host = portlessHost(for: request), host != ownHost
		else { return try await next.respond(to: request) }

		guard let matchingRoute = await controller.store.client(forHost: host)
		else { return Response(status: .notFound) }

		let headers = request.headers.reduce(Models.HTTPHeaders(), {
			var headers = $0
			headers.add(value: $1.value, for: $1.name)
			return headers
		})
		let request = HTTPRequest(
			host: host,
			url: URL(string: request.url.description)!,
			method: request.method.string,
			headers: headers,
			body: request.body.string.flatMap { .text($0) }
		)
		let response = try await matchingRoute.send(request)

		return response.asVaporResponse
	}

	private func portlessHost(for request: Request) -> String? {
		request.headers[.host].first?.split(separator: ":").first.map(String.init)
	}
}
