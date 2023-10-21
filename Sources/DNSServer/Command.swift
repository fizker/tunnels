import ArgumentParser

private struct Server {
	var host: String
	var ip: [UInt8]
}

extension Server: ExpressibleByArgument {
	init?(argument: String) {
		do {
			try self.init(arg: argument)
		} catch {
			return nil
		}
	}

	init(arg: String) throws {
		let components = arg.split(separator: "=")
		guard components.count == 2
		else { throw ValidationError("Host map must follow the form <host>=<ip> where host is a host name and ip is a valid IPv4 address.") }

		let rawIP = components[1].split(separator: ".").map { UInt8($0) }
		ip = rawIP.compactMap { $0 }

		guard ip.count == 4
		else { throw ValidationError("Host map must follow the form <host>=<ip> where host is a host name and ip is a valid IPv4 address.") }

		self.host = String(components[0])
	}
}

@main
struct Command: AsyncParsableCommand {
	@Argument var port: Int = 53

	@Option
	private var servers: [Server]

	func run() async throws {
		print("""
		Known servers:
		\(servers.map { "\($0.host): \($0.ip.map(\.description).joined(separator: "."))" }.joined(separator: "\n"))
		""")

		let kvPairs = servers.map { ($0.host, ResourceRecord.Data.ipV4($0.ip[0], $0.ip[1], $0.ip[2], $0.ip[3])) }
		let server = try await DNSServer(port: port, hostMap: .init(kvPairs, uniquingKeysWith: { a, b in a }))
		print("Server is up")
		try await server.waitUntilClose()
	}
}
