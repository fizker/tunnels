import Foundation
import Models

enum BodyStorage: String, Codable {
	/// The body, if present, is stored inside the HTTPRequest.
	case `internal`
	/// The body is stored next to the JSON file.
	case external
}

struct Log: Codable {
	typealias ID = HTTPRequest.ID

	var requestReceived: Date
	var responseSent: Date
	var id: ID { request.id }

	var request: HTTPRequest
	var requestBody: BodyStorage = .internal
	var response: HTTPResponse
}
