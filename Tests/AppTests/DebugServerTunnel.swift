import DebugServer
import Foundation
import OAuth2Models
import Testing
import TunnelClient
import TunnelModels
import TunnelServer

struct PasswordCredentials: Credentials {
	var username: String
	var password: String

	var request: PasswordAccessTokenRequest {
		.init(username: username, password: password)
	}
}

struct StartDebugServer: SuiteTrait, TestTrait, TestScoping {
	var port: Int

	func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
		let debugServer = try await DebugServer(port: "\(port)")
		try await debugServer.start()

		do {
			try await function()
		} catch {
			try? await debugServer.stop()
			throw error
		}
		try? await debugServer.stop()
	}
}

struct DebugServerTunnel: SuiteTrait, TestTrait, TestScoping {
	var tunnelServerPort: Int
	var debugServerPort: Int
	var debugServerHostName: String

	func provideScope(for test: Test, testCase: Test.Case?, performing function: @Sendable () async throws -> Void) async throws {
		// start tunnel server and debug server
		let tunnelServer = try await TunnelServer(
			environmentVars: .init([
				.port: "\(tunnelServerPort)",
			]),
		)
		try await tunnelServer.start()

		let debugServer = try await DebugServer(port: "\(debugServerPort)")
		try await debugServer.start()

		let logName = UUID()
		let fm = FileManager.default
		let storagePath = fm.temporaryDirectory.appending(components: "DebugServerTunnel", "TunnelClient", "\(logName)")

		print("TunnelClient logs are stored at \(storagePath)")

		// when tunnel server is running, start tunnel client
		let client = Client(
			serverURL: .init("http://localhost:\(tunnelServerPort)")!,
			proxies: [
				.init(localPort: debugServerPort, host: debugServerHostName),
			],
			credentials: PasswordCredentials(username: "regular", password: "1234"),
			logStorage: try await .init(storage: .init(storagePath).unwrap()),
			acmeSetupDownloadPath: nil,
		)
		try await client?.connect()

		do {
			try await function()
		} catch {
			try? await debugServer.stop()
			try? await tunnelServer.stop()
			throw error
		}

		try? await debugServer.stop()
		try? await tunnelServer.stop()

	}
}
