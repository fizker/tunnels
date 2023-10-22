import ArgumentParser
import Foundation
import TunnelsClient

@main
struct Client: AsyncParsableCommand {
	@Option(name: .shortAndLong, parsing: .upToNextOption)
	var proxies: [Proxy]

	@Option var tunnelServer: String = "http://localhost:8110"

	func run() async throws {
		let client = TunnelClient(proxies: proxies)
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
