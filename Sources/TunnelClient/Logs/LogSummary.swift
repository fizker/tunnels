import Foundation
import Models

public struct LogSummary: Codable {
	public var id: Log.ID
	public var host: String
	public var path: String
	public var requestReceived: Date
	public var requestMethod: HTTPMethod
	public var responseSent: Date
	public var responseStatus: HTTPStatus
	/// The response time in milliseconds
	public var responseTime: Double
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
		responseTime = log.responseTime
	}
}
