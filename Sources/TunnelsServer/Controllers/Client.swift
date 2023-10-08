import Foundation
import Models
import Vapor

/// An instance of TunnelsClient, from the perspective of the server. It supports sending a HTTPRequeste and awaiting the response.
class Client {
	let webSocket: WebSocket

	var pendingRequests: [HTTPRequest.ID: CheckedContinuation<HTTPResponse, Never>] = [:]
	var pendingResponses: [HTTPResponse] = []

	init(webSocket: WebSocket) {
		self.webSocket = webSocket

		webSocket.onText { [weak self] ws, data in
			try! self?.handleResponse(json: data)
		}
	}

	func send(_ req: HTTPRequest) async throws -> HTTPResponse {
		let encoder = JSONEncoder()
		let data = try encoder.encode(req)
		let json = String(data: data, encoding: .utf8)!
		try await webSocket.send(json)

		if let res = pendingResponses.first(where: { $0.id == req.id }) {
			pendingResponses.removeAll(where: { $0.id == req.id })
			return res
		}

		return await withCheckedContinuation { continuation in
			pendingRequests[req.id] = continuation
		}
	}

	private func handleResponse(json: String) throws {
		let decoder = JSONDecoder()
		let data = json.data(using: .utf8)!
		let res = try decoder.decode(HTTPResponse.self, from: data)

		guard let cont = pendingRequests[res.id]
		else {
			pendingResponses.append(res)
			return
		}

		cont.resume(returning: res)
		pendingRequests[res.id] = nil
	}
}
