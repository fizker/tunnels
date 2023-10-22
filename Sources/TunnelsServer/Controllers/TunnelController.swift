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

	func client(forHost host: String) -> Client? {
		return connectedClients.first { client in
			client.hosts.contains(host)
		}
	}

	func connectClient(req: Request, webSocket ws: WebSocket, host: String) throws {
		guard let _ = tunnels[host]
		else { throw TunnelError.notFound }

		guard client(forHost: host) != nil
		else { throw TunnelError.alreadyBound }

		let client = Client(webSocket: ws)
		client.hosts.append(host)
		connectedClients.append(client)

		ws.onClose.whenComplete { [weak self] _ in
			self?.connectedClients.removeAll { $0.webSocket.isClosed }
		}
	}
}
