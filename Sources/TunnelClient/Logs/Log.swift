public import Foundation
public import TunnelModels

public enum BodyStorage: Codable, Sendable {
	/// The body, if present, is stored inside the HTTPRequest.
	case included
	/// The body is stored next to the JSON file.
	case separate(filename: String)
}

public struct Log: Codable, Sendable {
	public typealias ID = HTTPRequest.ID

	public var id: ID { request.id }

	public var requestReceived: Date
	public var request: HTTPRequest
	public var requestBody: BodyStorage = .included

	public var responseSent: Date?
	/// The response time in milliseconds
	public var responseTime: Double?
	public var response: HTTPResponse?
	public var responseBody: BodyStorage = .included

	init(request: HTTPRequest, requestReceived: Date = .now) {
		self.request = request
		self.requestReceived = requestReceived
	}

	mutating func set(response: HTTPResponse) {
		self.responseSent = .now
		self.responseTime = requestReceived.timeIntervalSinceNow * -1000
		self.response = response
	}
}
