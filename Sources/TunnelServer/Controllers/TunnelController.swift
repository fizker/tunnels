import Models
import Vapor
import WebSocket

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
	var clientStore = ClientStore()

	func all(req: Request) async throws -> [TunnelDTO] {
		return await clientStore.connectedClients.flatMap(\.hosts).map(TunnelDTO.init(host:))
	}

	func connectClient(req: Request, webSocket: WebSocketHandler) async throws {
		let client = Client(webSocket: webSocket)
		await clientStore.add(client)
	}
}
