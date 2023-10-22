import Foundation
import Models
import Vapor

protocol TunnelStore {
	func addTunnel(config: TunnelConfiguration) async -> Result<TunnelDTO, TunnelError>
}

/// An instance of TunnelsClient, from the perspective of the server. It supports sending a HTTPRequeste and awaiting the response.
class Client {
	let webSocket: WebSocket

	var hosts: [String] = []

	var pendingRequests: [HTTPRequest.ID: CheckedContinuation<HTTPResponse, Never>] = [:]
	var pendingResponses: [HTTPResponse] = []

	init(webSocket: WebSocket, tunnelStore: TunnelStore) {
		self.webSocket = webSocket

		webSocket.onClientMessage { [weak self] ws, data in
			guard let self
			else { return }

			switch data {
			case let .response(res):
				try handle(res)
			case let .addTunnel(config):
				switch await tunnelStore.addTunnel(config: config) {
				case let .success(tunnel):
					hosts.append(tunnel.host)
				case let .failure(error):
					try await ws.send(.error(error))
				}
			case let .removeTunnel(host: host):
				hosts.removeAll { $0 == host }
			}
		}
	}

	func send(_ req: HTTPRequest) async throws -> HTTPResponse {
		try await webSocket.send(.request(req))

		if let res = pendingResponses.first(where: { $0.id == req.id }) {
			pendingResponses.removeAll(where: { $0.id == req.id })
			return res
		}

		return await withCheckedContinuation { continuation in
			pendingRequests[req.id] = continuation
		}
	}

	private func handle(_ res: HTTPResponse) throws {
		guard let cont = pendingRequests[res.id]
		else {
			pendingResponses.append(res)
			return
		}

		cont.resume(returning: res)
		pendingRequests[res.id] = nil
	}
}
