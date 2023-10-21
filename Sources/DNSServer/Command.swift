import ArgumentParser

private struct KnownDomainName {
	var domainName: String
	var ip: [UInt8]
}

extension KnownDomainName: ExpressibleByArgument {
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

		self.domainName = String(components[0])
	}
}

@main
struct Command: AsyncParsableCommand {
	@Argument var port: Int = 53

	@Option(name: .shortAndLong, parsing: .remaining)
	private var domainNames: [KnownDomainName]

	func run() async throws {
		print("""
		Known servers:
		\(domainNames.map { "\($0.domainName): \($0.ip.map(\.description).joined(separator: "."))" }.joined(separator: "\n"))
		""")

		let kvPairs = domainNames.map { ($0.domainName, ResourceRecord.Data.ipV4($0.ip[0], $0.ip[1], $0.ip[2], $0.ip[3])) }
		let server = try await DNSServer(port: port, hostMap: .init(kvPairs, uniquingKeysWith: { a, b in a }))
		print("Server is up")
		try await server.waitUntilClose()
	}
}
