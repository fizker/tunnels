import AsyncHTTPClient
import Models

extension Client {
	func handle(_ req: HTTPRequest) async throws -> HTTPResponse {
		guard let proxy = proxies.first(where: { $0.host == req.host })
		else { throw ClientError.invalidHost(req.host) }

		var request = HTTPClientRequest(url: "http://localhost:\(proxy.localPort)\(req.path)")
		request.method = .RAW(value: req.method)
		request.headers = .init(req.headers.flatMap { (key, values) in values.map { (key, $0) } })
		request.body = switch req.body {
		case let .text(text):
			.bytes(text.data(using: .utf8)!)
		case let .binary(data):
			.bytes(data)
		case nil:
			nil
		}

		let client = HTTPClient(configuration: .init(redirectConfiguration: .disallow))
		do {
			let response = try await client.execute(request, timeout: .seconds(30))
			let res = try await HTTPResponse(id: req.id, response: response)
			try await client.shutdown()

			return res
		} catch {
			try await client.shutdown()
			throw error
		}
	}
}
