import ArgumentParser
import Models
import TunnelClient
import WebURL

@main
struct StartClientCommand: AsyncParsableCommand {
	@Option(name: .shortAndLong, parsing: .upToNextOption)
	var proxies: [Proxy]

	@Option(name: .shortAndLong, transform: {
		guard let url = WebURL($0)
		else { throw ValidationError("Invalid URL.") }
		guard url.path.isEmpty || url.path == "/"
		else { throw ValidationError("Server URL must be scheme, host and port only.") }
		return url
	})
	var server: WebURL = WebURL("http://localhost:8110")!

	@Option(name: .shortAndLong)
	var logs: String = "logs"

	@Option(name: .shortAndLong, transform: { try ClientCredentials(argument: $0) })
	var credentials: ClientCredentials

	func run() async throws {
		let logStorage = try await LogStorage(storagePath: logs)

		guard let client = Client(
			serverURL: server,
			proxies: proxies,
			clientCredentials: credentials,
			logStorage: logStorage
		)
		else { throw ValidationError("Failed to create client.") }

		try await client.connect()

		try await client.waitUntilClose()
	}
}

extension Proxy: ExpressibleByArgument {
	public init?(argument: String) {
		let components = argument.split(separator: "=")
		guard
			components.count == 2,
			let port = Int(components[1])
		else { return nil }

		self.init(localPort: port, host: String(components[0]))
	}
}

extension ClientCredentials {
	init(argument: String) throws {
		let components = argument.split(separator: "=", maxSplits: 1)
		guard components.count == 2
		else { throw ValidationError("Credentials must be formatted like <clientID>=<clientSecret>") }

		self.init(
			clientID: String(components[0]),
			clientSecret: String(components[1])
		)
	}
}
