import ArgumentParser
import Foundation
import TunnelClient

@main
struct StartClientCommand: AsyncParsableCommand {
	@Option(name: .shortAndLong, parsing: .upToNextOption)
	var proxies: [Proxy]

	@Option(name: .shortAndLong, transform: {
		guard let url = URL(string: $0)
		else { throw ValidationError("Invalid URL.") }
		guard url.path().isEmpty || url.path() == "/"
		else { throw ValidationError("Server URL must be scheme, host and port only.") }
		return url
	})
	var server: URL = URL(string: "http://localhost:8110")!

	@Option(name: .shortAndLong)
	var logs: String = "logs"

	func run() async throws {
		let logStorage = try LogStorage(storagePath: logs)

		guard let client = Client(serverURL: server, proxies: proxies, logStorage: logStorage)
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
