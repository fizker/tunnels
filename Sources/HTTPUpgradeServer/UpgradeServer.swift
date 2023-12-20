import Vapor

/// A HTTP server that upgrades from unencrypted HTTP to one of the supported ``SupportedProtocol``s.
public class UpgradeServer {
	public struct StorageKey: Vapor.StorageKey {
		public typealias Value = UpgradeServer
	}

	var app: Application

	public init(port: Int = 80, upgradedHost: String, upgradedPort: Int? = nil) {
		var env = Environment(name: "upgrade")

		env.arguments.append("serve")
		env.arguments.append("--port")
		env.arguments.append("\(port)")

		self.app = Application(env)

		app.http.server.configuration.hostname = "0.0.0.0"

		app.middleware.use(UpgradeMiddleware(upgradedHost: upgradedHost, upgradedPort: upgradedPort))
	}

	/// Starts the server and attaches itself to the storage of the given ``Application``.
	public func start(topLevelApplication: Application) throws {
		try app.start()

		topLevelApplication.storage[StorageKey.self] = self
	}

	deinit {
		app.shutdown()
	}
}
