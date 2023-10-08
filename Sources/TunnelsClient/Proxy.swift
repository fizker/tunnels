import AsyncHTTPClient
import Foundation
import Models
import NIOHTTP1

struct Proxy {
	var localPort: Int
	var remoteName: String
	var remoteID: UUID

	func handle(_ req: HTTPRequest) async throws -> HTTPResponse {
		var request = HTTPClientRequest(url: "http://localhost:\(localPort)\(req.url)")
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

extension HTTPResponse {
	public init(id: UUID, response: HTTPClientResponse) async throws {
		try await self.init(
			id: id,
			status: response.status.asStatus,
			headers: .init(from: response),
			body: .init(from: response)
		)
	}
}

extension HTTPBody {
	init?(from response: HTTPClientResponse) async throws {
		guard
			let type = response.headers.first(name: "content-type")?.lowercased(),
			let length = response.headers.first(name: "content-length").flatMap(Int.init)
		else { return nil }

		var rawContent = try await response.body.collect(upTo: length)
		let content = rawContent.readData(length: length)!
		if type.starts(with: "text/") || type.starts(with: "application/json") {
			self = .text(String(data: content, encoding: .utf8)!)
		} else {
			self = .binary(content)
		}
	}
}

extension Models.HTTPHeaders {
	init(from response: HTTPClientResponse) {
		self = response.headers.reduce(HTTPHeaders()) {
			var headers = $0
			headers.add(value: $1.value, for: $1.name)
			return headers
		}
	}
}

extension HTTPResponseStatus {
	var asStatus: HTTPStatus {
		return .init(code: code, reason: reasonPhrase)
	}
}
