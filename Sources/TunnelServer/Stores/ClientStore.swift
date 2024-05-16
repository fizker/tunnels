import Models

actor ClientStore {
	var connectedClients: [Client] = []

	func client(forHost host: String) async -> Client? {
		for client in connectedClients {
			if await client.hosts.contains(host) {
				return client
			}
		}

		return nil
	}

	func client(awaitingRequest id: HTTPRequest.ID) async -> Client? {
		for client in connectedClients {
			if await client.pendingRequests[id] != nil {
				return client
			}
		}

		return nil
	}

	func add(_ client: Client) {
		connectedClients.append(client)
		Task {
			await client.webSocket.webSocket.onClose.whenComplete { [weak self] _ in
				guard let self
				else { return }
				Task {
					await self.removeClosedClients()
				}
			}
		}
	}

	func removeClosedClients() async {
		connectedClients = await withTaskGroup(of: (Client, Bool).self) { group in
			for client in connectedClients {
				group.addTask {
					(client, await client.webSocket.webSocket.isClosed)
				}
			}

			var clients = [Client]()
			for await (client, isClosed) in group {
				if !isClosed {
					clients.append(client)
				}
			}
			return clients
		}
	}
}
