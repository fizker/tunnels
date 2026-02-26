import ArgumentParser
import TunnelServer

struct StartCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "start",
	)

	func run() async throws {
		try await runServer()
	}
}
