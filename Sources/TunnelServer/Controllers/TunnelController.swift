import Common
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

actor TunnelController {
	var clientStore = ClientStore()

	func all(req: Request) async throws -> [TunnelDTO] {
		var dtos: [TunnelDTO] = []
		for client in await clientStore.connectedClients {
			let hosts = await client.hosts
			dtos.append(contentsOf: hosts.map(TunnelDTO.init(host:)))
		}
		return dtos
	}

	func connectClient(req: Request, webSocket: WebSocketHandler) async throws {
		let userID = try req.auth.require(User.self).id
		let userStore = req.application.userStore
		let acme = req.application.acmeHandler
		let client = Client(webSocket: webSocket) { [weak userStore, weak acme] hosts in
			guard let userStore, !hosts.isEmpty
			else { return }

			if let acme {
				Task {
					await acme.register(endpoints: hosts)
				}
			}

			Task {
				do {
					try await userStore.update(hosts: hosts, for: userID)
				} catch {
					#warning("TODO: Log error")
				}
			}
		}
		await clientStore.add(client)
	}

	func requestBody(req: Request, id: HTTPRequest.ID) async throws -> Response {
		guard let client = await clientStore.client(awaitingRequest: id)
		else { throw Abort(.notFound) }

		let request = await client.pendingRequests[id]

		guard let stream = request?.body
		else { throw Abort(.notFound) }

		return Response(body: Response.Body(stream: stream))
	}

	func collectResponse(req: Request, id: HTTPRequest.ID) async throws {
		guard let client = await clientStore.client(awaitingRequest: id)
		else { throw Abort(.notFound) }

		let deferred = Deferred(becoming: (any Error)?.self)
		let stream = req.body.stream(on: req.eventLoop.next()) {
			deferred.resolve($0)
		}
		await client.registerResponseStream(stream, for: id)

		let error = try await deferred.value
		if let error {
			throw error
		}
	}
}
