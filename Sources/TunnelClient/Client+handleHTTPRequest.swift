import AsyncHTTPClient
import Models

extension Client {
	func handle(_ req: HTTPRequest) async throws -> HTTPResponse {
		guard let proxy = proxies.first(where: { $0.host == req.host })
		else { throw ClientError.invalidHost(req.host) }

		var request = HTTPClientRequest(url: "http://localhost:\(proxy.localPort)\(req.url)")
		request.method = .RAW(value: req.method)
		request.headers = .init(req.headers.map { ($0, $1.joined(separator: " ")) })
		request.body = switch req.body {
		case let .text(text):
			.bytes(text.data(using: .utf8)!)
		case let .binary(data):
			.bytes(data)
		case nil:
			nil
		}

		let client = HTTPClient()
		let response = try await client.execute(request, timeout: .seconds(30))
		let res = try await HTTPResponse(id: req.id, response: response)
		try await client.shutdown()

		return res
	}

	private func body(for response: HTTPClientResponse) async throws -> HTTPBody? {
		guard
			let type = response.headers.first(name: "content-type")?.lowercased(),
			let length = response.headers.first(name: "content-length").flatMap(Int.init)
		else { return nil }

		var rawContent = try await response.body.collect(upTo: length)
		let content = rawContent.readData(length: length)!
		if type.starts(with: "text/") || type.starts(with: "application/json") {
			return .text(String(data: content, encoding: .utf8)!)
		} else {
			return .binary(content)
		}
	}
}
