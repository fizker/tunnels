import Foundation

public struct HTTPStatus: Codable {
	public var code: UInt
	public var reason: String

	public init(code: UInt, reason: String) {
		self.code = code
		self.reason = reason
	}

	public init(code: Int, reason: String) {
		self.init(code: UInt(code), reason: reason)
	}
}

public struct HTTPResponse: Codable {
	public var id: HTTPRequest.ID
	public var status: HTTPStatus
	public var headers: HTTPHeaders
	public var body: HTTPBody?

	public init(id: UUID, status: HTTPStatus, headers: HTTPHeaders = .init(), body: HTTPBody? = nil) {
		self.id = id
		self.status = status
		self.headers = headers
		self.body = body
	}
}

extension HTTPStatus: CustomStringConvertible {
	public var description: String {
		"\(code) \(reason)"
	}
}

extension HTTPResponse: CustomStringConvertible {
	public var description: String {
		"HTTPResponse \(id): \(status)"
	}
}
