import Models

actor ClientStore {
	var connectedClients: [Client] = []

	func client(forHost host: String) -> Client? {
		return connectedClients.first { client in
			client.hosts.contains(host)
		}
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
