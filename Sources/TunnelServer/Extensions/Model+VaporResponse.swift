import Models
import Vapor

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
