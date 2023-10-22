import Models
import Vapor

struct TunnelDTO: Codable {
	var host: String
}

struct TunnelUpdateRequest: Codable {
	var host: String
}

class TunnelController {
	var tunnels: [String: TunnelDTO] = [:]
	var connectedClients: [Client] = []

	func all(req: Request) async throws -> [TunnelDTO] {
		return tunnels.map(\.value)
	}

	func add(req: Request) async throws -> TunnelDTO {
		let dto = try req.content.decode(TunnelUpdateRequest.self)
		let model = TunnelDTO(host: dto.host)

		guard tunnels[model.host] == nil
		else { throw Abort(.badRequest, reason: "Host already in use") }

		tunnels[model.host] = model
		return model
	}

	func get(req: Request, host: String) async throws -> TunnelDTO? {
		return tunnels[host]
	}

	func update(req: Request, host: String) async throws -> TunnelDTO {
		let dto = try req.content.decode(TunnelUpdateRequest.self)
		var model = tunnels[host] ?? .init(host: host)
		model.host = dto.host
		tunnels[host] = model
		return model
	}

	func delete(req: Request, host: String) async throws {
		tunnels.removeValue(forKey: host)
	}

	func connectClient(req: Request, webSocket: WebSocket) throws {
		let client = Client(webSocket: webSocket)
		add(client)
	}

	func client(forHost host: String) -> Client? {
		return connectedClients.first { client in
			client.hosts.contains(host)
		}
	}

	private func add(_ client: Client) {
		connectedClients.append(client)
		client.webSocket.onClose.whenComplete { [weak self] _ in
			self?.connectedClients.removeAll { $0.webSocket.isClosed }
		}
	}
}
