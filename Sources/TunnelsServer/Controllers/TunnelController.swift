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
	var tunnels: [String: TunnelDTO] = [:]
	var connectedClients: [Client] = []

	func all(req: Request) async throws -> [TunnelDTO] {
		return tunnels.map(\.value)
	}

	func add(req: Request) async throws -> TunnelDTO {
		let config = try req.content.decode(TunnelConfiguration.self)
		return try await addTunnel(config: config).get()
	}

	func get(req: Request, host: String) async throws -> TunnelDTO? {
		return tunnels[host]
	}

	func update(req: Request, host: String) async throws -> TunnelDTO {
		let config = try req.content.decode(TunnelConfiguration.self)
		var model = tunnels[host] ?? .init(host: host)
		model.host = config.host
		tunnels[host] = model
		return model
	}

	func delete(req: Request, host: String) async throws {
		tunnels.removeValue(forKey: host)
	}

	func connectClient(req: Request, webSocket: WebSocket) throws {
		let client = Client(webSocket: webSocket, tunnelStore: self)
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

extension TunnelController: TunnelStore {
	func addTunnel(config: TunnelConfiguration) async -> Result<TunnelDTO, TunnelError> {
		guard self.client(forHost: config.host) != nil
		else { return .failure(.alreadyBound(host: config.host)) }

		let tunnel = TunnelDTO(configuration: config)
		tunnels[config.host] = tunnel

		return .success(tunnel)
	}
}

extension TunnelError: AbortError {
	public var status: HTTPResponseStatus {
		switch self {
		case .alreadyBound:
			.conflict
		}
	}

	public var reason: String {
		switch self {
		case let .alreadyBound(host):
			"Host \(host) already in use"
		}
	}
}
