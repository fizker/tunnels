import ArgumentParser

@main
struct Command: AsyncParsableCommand {
	func run() async throws {
		print("Server is up")
	}
}
