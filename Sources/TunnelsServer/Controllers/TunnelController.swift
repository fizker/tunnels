import Vapor

struct TunnelDTO: Codable {
	var id: UUID
	var host: String
}

struct TunnelUpdateRequest: Codable {
	var host: String
}

class TunnelController {
	var tunnels: [UUID: TunnelDTO] = [:]
	var connectedClients: [(tunnel: TunnelDTO, client: Client)] = []

	func all(req: Request) async throws -> [TunnelDTO] {
		return tunnels.map(\.value)
	}

	func add(req: Request) async throws -> TunnelDTO {
		let dto = try req.content.decode(TunnelUpdateRequest.self)
		let model = TunnelDTO(id: UUID(), host: dto.host)
		tunnels[model.id] = model
		return model
	}

	func get(req: Request, id: UUID) async throws -> TunnelDTO? {
		return tunnels[id]
	}

	func update(req: Request, id: UUID) async throws -> TunnelDTO {
		let dto = try req.content.decode(TunnelUpdateRequest.self)
		var model = tunnels[id] ?? .init(id: id, host: "")
		model.host = dto.host
		tunnels[id] = model
		return model
	}

	func delete(req: Request, id: UUID) async throws {
		tunnels.removeValue(forKey: id)
	}

	func connectClient(req: Request, webSocket ws: WebSocket, id: UUID) throws {
		guard let dto = tunnels[id]
		else { throw Abort(.notFound) }

		connectedClients.append((dto, Client(webSocket: ws)))

		ws.onClose.whenComplete { [weak self] _ in
			self?.connectedClients.removeAll { $0.client.webSocket.isClosed }
		}
	}
}
