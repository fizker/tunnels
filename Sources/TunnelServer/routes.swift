import Foundation
import Vapor

extension TunnelDTO: Content {}

func routes(_ app: Application) throws {
	let tunnelController = TunnelController()

	app.middleware.use(AuthMiddleware(userStore: app.userStore))

	app.middleware.use(TunnelInterceptor(ownHost: app.environment.host, controller: tunnelController))

	app.get { req in
		return "It works!"
	}

	app.get("hello") { req -> String in
		return "Hello, world!"
	}

	app.group("auth") { app in
		app.get("summary") { try await $0.authController().summary() }
		app.post("token") { try await $0.authController().oauth2Token(req: $0) }

		app
		.group("client-credentials") { app in
			app.get { try $0.authController().clientCredentials(for: $0.auth.require()) }
			app.post { try await $0.authController().createClientCredentials(for: $0.auth.require()) }
			app.delete {
				try await $0.authController().removeClientCredentials(for: $0.auth.require())
				return HTTPResponseStatus.noContent
			}
		}
	}

	app
	.grouped(RequireUserMiddleware(.admin))
	.group("users") { app in
		app.get { try await $0.userController().users() }
		app.put(":username") { try await $0.userController().upsertUser(usernameParam: "username") }
		app.delete(":username") {
			try await $0.userController().removeUser(usernameParam: "username")
			return HTTPResponseStatus.noContent
		}
	}

	app
	.grouped(RequireUserMiddleware())
	.group("tunnels") { app in
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

		app.webSocket("client", onUpgrade: { try await tunnelController.connectClient(req: $0, webSocket: $1) })
	}
}
