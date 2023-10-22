import Vapor

struct TunnelDTO: Codable {
	var host: String
}

struct TunnelUpdateRequest: Codable {
	var host: String
}

class TunnelController {
	var tunnels: [String: TunnelDTO] = [:]
	var connectedClients: [(tunnel: TunnelDTO, client: Client)] = []

	func all(req: Request) async throws -> [TunnelDTO] {
		return tunnels.map(\.value)
	}

	func add(req: Request) async throws -> TunnelDTO {
		let dto = try req.content.decode(TunnelUpdateRequest.self)
		let model = TunnelDTO(host: dto.host)
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

	func connectClient(req: Request, webSocket ws: WebSocket, host: String) throws {
		guard let dto = tunnels[host]
		else { throw Abort(.notFound) }

		connectedClients.append((dto, Client(webSocket: ws)))

		ws.onClose.whenComplete { [weak self] _ in
			self?.connectedClients.removeAll { $0.client.webSocket.isClosed }
		}
	}
}
