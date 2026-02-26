import ArgumentParser
import Foundation
import SystemPackage
import TunnelModels
import TunnelServer

let coder = Coder()

struct UnpackSetupCommand: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		commandName: "unpack",
		abstract: "Unpacks a downloaded setup file for use in starting a server",
	)

	@Argument(
		help: "The path to a downloaded setup file.",
		transform: { path -> SysController.Setup in
			let url = URL(fileURLWithPath: path)
			let data = try Data(contentsOf: url)
			return try coder.decode(data)
		},
	)
	var setup: SysController.Setup

	@Option(
		name: [ .short, .customLong("user-storage") ],
		help: "The path to unpack the users to",
		transform: FilePath.init(_:),
	)
	var userStoragePath: FilePath

	@Option(
		name: [ .customShort("s"), .customLong("acme-setup") ],
		transform: FilePath.init(_:),
	)
	var acmeSetupPath: FilePath

	@Option(
		name: [ .customShort("d"), .customLong("acme-data") ],
		transform: FilePath.init(_:),
	)
	var acmeDataPath: FilePath

	func run() async throws {
		try await UserStore.import(downloadedData: setup, storagePath: userStoragePath)

		if let data = setup.acmeData {
			let encoded = try coder.encode(data)
			try await encoded.write(toFileAt: acmeDataPath)
		}

		if var setup = setup.acmeSetup {
			setup.storagePath = acmeDataPath.string
			let encoded = try coder.encode(setup)
			try await encoded.write(toFileAt: acmeSetupPath)
		}
	}
}
