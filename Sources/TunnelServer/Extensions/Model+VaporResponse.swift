import Models
import Vapor

extension Models.HTTPResponse {
	private func vaporBody(stream: ResponseStream) -> Response.Body {
		if headers.firstHeader(named: "content-length") == nil {
			let buffer: ByteBuffer
			switch self.body {
			case let .text(value):
				buffer = ByteBuffer(string: value)
			case let .binary(data):
				buffer = ByteBuffer(data: data)
			case .stream:
				return .init(stream: stream)
			case .none:
				return .empty
			}

			return .init(stream: { writer in
				_ = writer.write(.buffer(buffer))
				.map { _ in
					writer.write(.end)
				}
			}, count: -1)
		}

		let body: Response.Body = switch self.body {
		case let .text(value):
			.init(string: value)
		case let .binary(data):
			.init(data: data)
		case .stream:
			.init(stream: stream)
		case .none:
			.empty
		}

		return body
	}

	func asVaporResponse(stream: ResponseStream) -> Response {
		var headers = self.headers

		headers.removeAll(named: "connection")
		headers.removeAll(named: "date")

		return Response(
			status: .custom(code: status.code, reasonPhrase: status.reason),
			headers: .init(headers.flatMap { key, values in values.map { (key, $0) } }),
			body: vaporBody(stream: stream)
		)
	}
}

extension TunnelError: AbortError {
	public var status: HTTPResponseStatus {
		switch self {
		case .alreadyBound:
			.conflict
		}
	}

	public var reason: String {
		switch self {
		case let .alreadyBound(host):
			"Host \(host) already in use"
		}
	}
}
