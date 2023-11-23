import Foundation
import Models

struct Log: Codable {
	typealias ID = HTTPRequest.ID

	var requestReceived: Date
	var responseSent: Date
	var id: ID { request.id }

	var request: HTTPRequest
	var response: HTTPResponse
}
