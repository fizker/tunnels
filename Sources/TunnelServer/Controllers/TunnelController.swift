import Models
import Vapor

struct TunnelDTO: Codable {
	var host: String

	init(host: String) {
		self.host = host
	}

	init(configuration: TunnelConfiguration) {
		self.init(host: configuration.host)
	}
}

class TunnelController {
	var store = TunnelStoreDB()

	func all(req: Request) async throws -> [TunnelDTO] {
		return await store.tunnels.map(\.value)
	}

	func add(req: Request) async throws -> TunnelDTO {
		let config = try req.content.decode(TunnelConfiguration.self)
		return try await store.addTunnel(config: config).get()
	}

	func get(req: Request, host: String) async throws -> TunnelDTO? {
		return await store.tunnels[host]
	}

	func update(req: Request, host: String) async throws -> TunnelDTO {
		let config = try req.content.decode(TunnelConfiguration.self)
		return try await store.updateTunnel(host: host, config: config)
	}

	func delete(req: Request, host: String) async throws {
		try await store.removeTunnels(forHost: host)
	}

	func connectClient(req: Request, webSocket: WebSocket) async throws {
		let client = Client(webSocket: webSocket, tunnelStore: store)
		await store.add(client)
	}
}
