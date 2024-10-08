import Models
import Vapor

struct TunnelInterceptor: AsyncMiddleware {
	var ownHost: String
	var controller: TunnelController

	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		let logger = request.logger(label: "TunnelInterceptor")

		guard let host = portlessHost(for: request), host != ownHost
		else {
			logger.info("Handling request with regular routes")
			return try await next.respond(to: request)
		}

		guard let matchingRoute = await controller.clientStore.client(forHost: host)
		else {
			logger.info("Could not find client for host \(host)")
			return Response(
				status: .badGateway,
				headers: ["content-type": "text/html"],
				body: .init(string: """
				<!doctype html>

				<h1>No gateway found</h1>

				<p>No gateway was found for host \(host).</p>
				""")
			)
		}

		let headers = request.headers.reduce(Models.HTTPHeaders(), {
			var headers = $0
			headers.add(value: $1.value, for: $1.name)
			return headers
		})
		let clientRequest = HTTPRequest(
			host: host,
			path: request.url.description,
			method: request.method.string,
			headers: headers,
			body: .stream
		)

		logger.info("Routing \(clientRequest)")

		let response = try await matchingRoute.send(clientRequest, bodyStream: request.body.stream(on: request.eventLoop.next(), onFinish: { _ in }))

		logger.info("Got response \(response.0)")

		return response.0.asVaporResponse(stream: response.1)
	}

	private func portlessHost(for request: Request) -> String? {
		request.headers[.host].first?.split(separator: ":").first.map(String.init)
	}
}
