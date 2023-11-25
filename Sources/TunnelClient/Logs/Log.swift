import Foundation
import Models

public enum BodyStorage: String, Codable {
	/// The body, if present, is stored inside the HTTPRequest.
	case `internal`
	/// The body is stored next to the JSON file.
	case external
}

public struct Log: Codable {
	public typealias ID = HTTPRequest.ID

	public var requestReceived: Date
	public var responseSent: Date
	public var id: ID { request.id }

	public var request: HTTPRequest
	public var requestBody: BodyStorage = .internal
	public var response: HTTPResponse
}
