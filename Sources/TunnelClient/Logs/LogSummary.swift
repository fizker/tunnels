import Foundation
import Models

struct LogSummary: Codable {
	var id: Log.ID
	var url: URL
	var requestReceived: Date
	var requestMethod: HTTPMethod
	var responseSent: Date
	var responseStatus: HTTPStatus
}
extension LogSummary {
	init(log: Log) {
		id = log.id
		url = log.request.url
		requestReceived = log.requestReceived
		requestMethod = log.request.method
		responseSent = log.responseSent
		responseStatus = log.response.status
	}
}
