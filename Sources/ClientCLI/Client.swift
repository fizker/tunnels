import ArgumentParser
import Foundation
import TunnelsClient

@main
struct Client: AsyncParsableCommand {
	@Argument var host: String
	@Argument var port: Int

	@Option var tunnelServer: String = "http://localhost:8110"

	func run() async throws {
		let proxy = Proxy(localPort: port, host: host)
		try await proxy.connect()

		print("Client started for local port \(port)")

		try await proxy.waitUntilClose()
	}
}

extension UUID: ExpressibleByArgument {
	public init?(argument: String) {
		self.init(uuidString: argument)
	}
}
