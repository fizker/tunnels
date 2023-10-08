import AsyncHTTPClient
import Foundation
import Models
import NIOHTTP1

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
		self = response.headers.reduce(Models.HTTPHeaders()) {
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
