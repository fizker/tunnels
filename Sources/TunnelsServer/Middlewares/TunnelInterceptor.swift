import Models
import Vapor

struct TunnelInterceptor: AsyncMiddleware {
	var ownHost: String
	var controller: TunnelController

	func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
		guard let host = portlessHost(for: request), host != ownHost
		else { return try await next.respond(to: request) }

		guard let matchingRoute = controller.connectedClients.first(where: { $0.tunnel.host == host })
		else { return Response(status: .notFound) }

		let headers = request.headers.reduce(Models.HTTPHeaders(), {
			var headers = $0
			headers.add(value: $1.value, for: $1.name)
			return headers
		})
		let request = HTTPRequest(url: URL(string: request.url.description)!, method: request.method.string, headers: headers, body: request.body.string.flatMap { .text($0) })
		let response = try await matchingRoute.client.send(request)

		return response.asVaporResponse
	}

	private func portlessHost(for request: Request) -> String? {
		request.headers[.host].first?.split(separator: ":").first.map(String.init)
	}
}

extension Models.HTTPResponse {
	var asVaporResponse: Response {
		let body: Response.Body = switch self.body {
		case let .text(value):
			.init(string: value)
		case let .binary(data):
			.init(data: data)
		case .none:
			.empty
		}

		return Response(
			status: .custom(code: status.code, reasonPhrase: status.reason),
			headers: .init(self.headers.map { ($0, $1.joined(separator: " ")) }),
			body: body
		)
	}
}
