import Foundation
import Vapor

extension TunnelDTO: Content {}

func routes(_ app: Application) throws {
	let tunnelController = TunnelController()
	app.middleware.use(TunnelInterceptor(ownHost: app.environment.host, controller: tunnelController))

	app.get { req in
		return "It works!"
	}

	app.get("hello") { req -> String in
		return "Hello, world!"
	}

	app.group("auth") { app in
		app.get("summary") { try await $0.authController().summary() }
	}

	app.group("tunnels") { app in
		app.get { try await tunnelController.all(req: $0) }
		app.post { try await tunnelController.add(req: $0) }

		app.group(":host") { app in
			app.get { try await tunnelController.get(req: $0, host: $0.parameters.require("host")) }
			app.put { try await tunnelController.update(req: $0, host: $0.parameters.require("host")) }
			app.delete {
				try await tunnelController.delete(req: $0, host: $0.parameters.require("host"))
				return HTTPStatus.noContent
			}
		}

		app.webSocket("client") { try await tunnelController.connectClient(req: $0, webSocket: $1) }
	}
}
