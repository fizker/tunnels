import Foundation
import Models

struct LogSummary: Codable {
	var id: Log.ID
	var host: String
	var path: String
	var requestReceived: Date
	var requestMethod: HTTPMethod
	var responseSent: Date
	var responseStatus: HTTPStatus
}
extension LogSummary {
	init(log: Log) {
		id = log.id
		host = log.request.host
		path = log.request.path
		requestReceived = log.requestReceived
		requestMethod = log.request.method
		responseSent = log.responseSent
		responseStatus = log.response.status
	}
}
