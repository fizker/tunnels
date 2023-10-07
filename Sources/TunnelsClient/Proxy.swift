import Foundation
import Models

struct Proxy {
	var localPort: Int
	var remoteName: String
	var remoteID: UUID

	func handle(_ req: HTTPRequest) async -> HTTPResponse {
		let headers = ["content-length": "11", "content-type": "text/plain"]
		return .init(id: req.id, status: .init(code: 400, reason: "OK"), headers: .init(headers), body: .text("hello world"))
	}
}
