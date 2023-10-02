import Foundation
import Vapor

extension TunnelDTO: Content {}

func routes(_ app: Application) throws {
	app.get { req in
		return "It works!"
	}

	app.get("hello") { req -> String in
		return "Hello, world!"
	}

	app.group("tunnels") { app in
		let tunnelController = TunnelController()

		app.get { try await tunnelController.all(req: $0) }
		app.post { try await tunnelController.add(req: $0) }

		app.group(":id") { app in
			app.get { try await tunnelController.get(req: $0, id: $0.parameters.require("id")) }
			app.put { try await tunnelController.update(req: $0, id: $0.parameters.require("id")) }
			app.delete {
				try await tunnelController.delete(req: $0, id: $0.parameters.require("id"))
				return HTTPStatus.noContent
			}
		}
	}
}

extension Optional: AsyncResponseEncodable where Wrapped: AsyncResponseEncodable {
	public func encodeResponse(for request: Request) async throws -> Response {
		guard let value = self.wrapped
		else { return Response.init(status: .notFound) }

		return try await value.encodeResponse(for: request)
	}
}
