import AsyncHTTPClient
import Foundation
import Models
import NIOCore
import NIOHTTP1

extension HTTPResponse {
	public init(id: UUID, response: HTTPClientResponse) {
		self.init(
			id: id,
			status: response.status.asStatus,
			headers: .init(from: response),
			body: .init(from: response)
		)
	}
}

extension HTTPBody {
	init?(from response: HTTPClientResponse) {
		guard let type = response.headers.first(name: "content-type")?.lowercased()
		else { return nil }

		self = .stream

//		let content: Data
//		if let length = response.headers.first(name: "content-length").flatMap(Int.init) {
//			var rawContent = try await response.body.collect(upTo: length)
//			content = rawContent.readData(length: length)!
//		} else {
//			var iterator = response.body.makeAsyncIterator()
//			var d = Data()
//			while let buffer = try await iterator.next() {
//				d.append(buffer)
//			}
//			content = d
//		}
//
//		if type.starts(with: "text/") || type.starts(with: "application/json") {
//			self = .text(String(data: content, encoding: .utf8)!)
//		} else {
//			self = .binary(content)
//		}
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

extension Data {
	mutating func append(_ buffer: ByteBuffer) {
		var buffer = buffer
		if let data = buffer.readData(length: buffer.readableBytes) {
			append(data)
		}
	}
}
