import Foundation

public typealias HTTPMethod = String

public struct HTTPRequest: Codable {
	public typealias ID = UUID

	public var id: ID
	public var host: String
	public var path: String
	public var method: HTTPMethod
	public var headers: HTTPHeaders
	public var body: HTTPBody?

	public init(id: UUID = .init(), host: String, path: String, method: HTTPMethod, headers: HTTPHeaders = .init(), body: HTTPBody? = nil) {
		self.id = id
		self.host = host
		self.path = path
		self.method = method
		self.headers = headers
		self.body = body
	}
}

extension HTTPRequest: CustomStringConvertible {
	public var description: String {
		"HTTPRequest (\(id)): \(host) \(method) \(path)"
	}
}
