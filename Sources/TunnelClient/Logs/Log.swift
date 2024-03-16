import Foundation
import Models

public enum BodyStorage: String, Codable, Sendable {
	/// The body, if present, is stored inside the HTTPRequest.
	case included
	/// The body is stored next to the JSON file.
	case separate
}

public struct Log: Codable, Sendable {
	public typealias ID = HTTPRequest.ID

	public var requestReceived: Date
	public var responseSent: Date
	/// The response time in milliseconds
	public var responseTime: Double
	public var id: ID { request.id }

	public var request: HTTPRequest
	public var requestBody: BodyStorage = .included
	public var response: HTTPResponse
}
