import ArgumentParser
import TunnelServer

struct StartCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "start",
		abstract: "Starts the TunnelServer."
	)

	func run() async throws {
		try await runServer()
	}
}
