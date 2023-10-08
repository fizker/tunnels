import ArgumentParser
import Foundation
import TunnelsClient

@main
struct Client: AsyncParsableCommand {
	//@Argument var remoteName: String
	@Argument
	var remoteID: UUID
	@Argument var port: Int

	@Option var tunnelServer: String = "http://localhost:8110"

	func run() async throws {
		try await connect(id: remoteID, port: port)

		print("Client started for local port \(port)")

		print("Client will close in 120s")
		try await Task.sleep(for: .seconds(120))
		print("Closing client")
	}
}

extension UUID: ExpressibleByArgument {
	public init?(argument: String) {
		self.init(uuidString: argument)
	}
}
