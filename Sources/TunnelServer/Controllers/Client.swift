import Common
import Foundation
import Models
import Vapor
import WebSocket

typealias RequestStream = AsyncThrowingStream<UInt8, any Error>
typealias ResponseStream = AsyncThrowingStream<UInt8, any Error>

struct PendingResponse {
	var response: HTTPResponse?
	var stream: ResponseStream?
}

/// An instance of TunnelClient, from the perspective of the server. It supports sending a HTTPRequest and awaiting the response.
actor Client {
	let webSocket: WebSocketHandler

	var hosts: [String] = []

	var pendingRequests: [HTTPRequest.ID: (
		cont: Deferred<(HTTPResponse, ResponseStream)>,
		body: RequestStream,
		response: PendingResponse
	)] = [:]

	init(webSocket: WebSocketHandler) {
		self.webSocket = webSocket

		webSocket.onClientMessage { [weak self] ws, data in
			try await self?.onWebSocketMessage(data)
		}
	}

	private func onWebSocketMessage(_ data: WebSocketClientMessage) async throws {
		switch data {
		case let .response(res):
			try handle(res)
		case let .addTunnel(config):
			hosts.append(config.host)
			try await webSocket.send(.tunnelAdded(config))
		case let .removeTunnel(host: host):
			hosts.removeAll { $0 == host }
			try await webSocket.send(.tunnelRemoved(TunnelConfiguration(host: host)))
		}
	}

	func send(_ req: HTTPRequest, bodyStream: RequestStream) async throws -> (HTTPResponse, ResponseStream) {
		let response = Deferred<(HTTPResponse, ResponseStream)>();
		pendingRequests[req.id] = (response, bodyStream, PendingResponse())

		try await webSocket.send(.request(req))

		return try await response.value
	}

	func registerResponseStream(_ stream: ResponseStream, for id: HTTPRequest.ID) {
		pendingRequests[id]?.response.stream = stream
		resolve(request: id)
	}

	private func handle(_ res: HTTPResponse) throws {
		pendingRequests[res.id]?.response.response = res
		resolve(request: res.id)
	}

	private func resolve(request id: HTTPRequest.ID) {
		guard let p = pendingRequests[id], let res = p.response.response, let stream = p.response.stream
		else { return }

		p.cont.resolve((res, stream))
		pendingRequests[res.id] = nil
	}
}
