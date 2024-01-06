import Models
import Vapor

extension Models.HTTPResponse {
	private var vaporBody: Response.Body {
		if headers.firstHeader(named: "content-length") == nil {
			// do stream
			let buffer: ByteBuffer? = switch self.body {
			case let .text(value):
				ByteBuffer(string: value)
			case let .binary(data):
				ByteBuffer(data: data)
			case .none:
				nil
			}

			return .init(stream: { writer in
				if let buffer {
					_ = writer.write(.buffer(buffer))
					.map { _ in
						writer.write(.end)
					}
				} else {
					_ = writer.write(.end)
				}
			}, count: -1)
		}

		let body: Response.Body = switch self.body {
		case let .text(value):
			.init(string: value)
		case let .binary(data):
			.init(data: data)
		case .none:
			.empty
		}

		return body
	}

	var asVaporResponse: Response {
		var headers = self.headers

		headers.removeAll(named: "connection")
		headers.removeAll(named: "date")

		return Response(
			status: .custom(code: status.code, reasonPhrase: status.reason),
			headers: .init(headers.flatMap { key, values in values.map { (key, $0) } }),
			body: vaporBody
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
