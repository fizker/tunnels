import Models

actor TunnelStoreDB: TunnelStore {
	var tunnels: [String: TunnelDTO] = [:]
	var connectedClients: [Client] = []

	func client(forHost host: String) -> Client? {
		return connectedClients.first { client in
			client.hosts.contains(host)
		}
	}

	func addTunnel(config: TunnelConfiguration) async -> Result<TunnelDTO, TunnelError> {
		guard self.client(forHost: config.host) == nil
		else { return .failure(.alreadyBound(host: config.host)) }

		let tunnel = TunnelDTO(configuration: config)
		tunnels[config.host] = tunnel

		return .success(tunnel)
	}

	func updateTunnel(host: String, config: TunnelConfiguration) async throws -> TunnelDTO {
		var model = tunnels[host] ?? .init(host: host)
		model.host = config.host
		tunnels[host] = model
		return model
	}

	func removeTunnels(forHost host: String) async throws {
		tunnels.removeValue(forKey: host)
	}

	func add(_ client: Client) {
		connectedClients.append(client)
		client.webSocket.onClose.whenComplete { [weak self] _ in
			guard let self
			else { return }
			Task {
				await self.removeClosedClients()
			}
		}
	}

	func removeClosedClients() {
		connectedClients.removeAll { $0.webSocket.isClosed }
	}
}
