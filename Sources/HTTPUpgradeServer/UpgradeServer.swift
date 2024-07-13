import CatchAll
import Vapor

/// A HTTP server that upgrades from unencrypted HTTP to one of the supported ``SupportedProtocol``s.
public actor UpgradeServer {
	public struct StorageKey: Vapor.StorageKey {
		public typealias Value = UpgradeServer
	}

	public private(set) var app: Application

	public init(port: Int = 80, requestUpgrade: @escaping UpgradeRequest) {
		var env = Environment(name: "upgrade")

		env.arguments.append("serve")
		env.arguments.append("--port")
		env.arguments.append("\(port)")

		self.app = Application(env)

		app.http.server.configuration.hostname = "0.0.0.0"

		let upgradeMiddleware = UpgradeMiddleware(requestUpgrade: requestUpgrade)
		app.middleware.use(CatchAllMiddleware { await upgradeMiddleware.handle($0) })
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
