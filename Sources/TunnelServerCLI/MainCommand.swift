import ArgumentParser

@main
struct MainCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "tunnel-server",
		subcommands: [
			StartCommand.self,
		],
		defaultSubcommand: StartCommand.self,
	)
}
