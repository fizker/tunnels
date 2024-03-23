import Binary
import NIO

package typealias HostMap = [String: ResourceRecord.Data]

private let cloudflareAddress = try! SocketAddress(ipAddress: "1.1.1.1", port: 53)

package class DNSServer {
	let port: Int
	let channel: any Channel
	let hostMap: HostMap
	let dnsProxyAddress: SocketAddress

	public init(
		port: Int = 53,
		dnsProxyAddress: SocketAddress = cloudflareAddress,
		hostMap: HostMap
	) async throws {
		self.port = port
		self.hostMap = hostMap
		self.dnsProxyAddress = dnsProxyAddress

		let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
		let bootstrap = DatagramBootstrap(group: group)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer {
				$0.pipeline.addHandler(DNSServerChannelHandler(
					port: port,
					hostMap: hostMap,
					dnsProxyAddress: dnsProxyAddress
				))
			}

		channel = try await bootstrap.bind(host: "0.0.0.0", port: port).get()
	}

	public convenience init(port: Int = 53, dnsProxyAddress: (address: String, port: Int)?, hostMap: HostMap) async throws {
		let proxy = try dnsProxyAddress.map { try SocketAddress(ipAddress: $0.address, port: $0.port) } ?? cloudflareAddress
		try await self.init(
			port: port,
			dnsProxyAddress: proxy,
			hostMap: hostMap
		)
	}

	public func waitUntilClose() async throws {
		try await channel.closeFuture.get()
	}
}

private class DNSServerChannelHandler: ChannelInboundHandler {
	package typealias InboundIn = AddressedEnvelope<ByteBuffer>
	package typealias OutboundOut = AddressedEnvelope<ByteBuffer>

	let port: Int
	let hostMap: HostMap
	let dnsProxyAddress: SocketAddress

	/// The key is the DNSPacket ID, and the value is the address of the original sender, that should get the response
	var pendingProxyRequests: [UInt16: SocketAddress] = [:]

	init(port: Int, hostMap: HostMap, dnsProxyAddress: SocketAddress) {
		self.port = port
		self.hostMap = hostMap
		self.dnsProxyAddress = dnsProxyAddress
	}

	package func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let input = unwrapInboundIn(data)

		print("Received message from \(input.remoteAddress)")

		var iterator = input.data.readableBytesView.makeBitIterator()
		do {
			let packet = try DNSPacket(iterator: &iterator)

			if packet.header.kind == .response {
				guard let remoteAddress = pendingProxyRequests.removeValue(forKey: packet.header.id)
				else {
					print("Got response for unknown packet")
					return
				}

				print("Received response for \(packet.header.id)")
				let output = AddressedEnvelope(remoteAddress: remoteAddress, data: input.data)
				context.write(wrapOutboundOut(output), promise: nil)
				return
			}

			let ipRequests = packet.questions.filter {
				$0.type == .hostAddress && $0.class == .internet
			}

			print("Got requests for \(ipRequests.map(\.name.value))")

			let answers = ipRequests.compactMap { packet -> ResourceRecord? in
				guard let data = hostMap[packet.name.value]
				else { return nil }

				return ResourceRecord(
					name: packet.name,
					type: .hostAddress,
					class: .internet,
					timeToLive: 100,
					data: data
				)
			}

			if answers.count != packet.questions.count {
				print("Unknown hosts were requested")
				if !answers.isEmpty {
					print("Some requested hosts were known though")
					print(packet.questions)
				}

				print("Sending \(packet.header.id) to proxy")
				pendingProxyRequests[packet.header.id] = input.remoteAddress
				let output = AddressedEnvelope(remoteAddress: dnsProxyAddress, data: input.data)
				context.write(wrapOutboundOut(output), promise: nil)
				return
			}

			let response = DNSPacket(
				header: Header(
					id: packet.header.id,
					kind: .response,
					opcode: packet.header.opcode,
					isAuthoritativeAnswer: false,
					isTruncated: false,
					isRecursionDesired: false,
					isRecursionAvailable: false,
					z: 0,
					responseCode: nil,
					questionCount: packet.header.questionCount,
					answerCount: UInt16(answers.count),
					authorityCount: 0,
					additionalCount: 0
				),
				questions: packet.questions,
				answers: answers
			)

			let output = AddressedEnvelope(remoteAddress: input.remoteAddress, data: ByteBuffer(bytes: response.asData))
			context.write(wrapOutboundOut(output) , promise: nil)
		} catch {
			print("Failed to read content")
			context.fireChannelRead(data)
		}
	}

	package func channelReadComplete(context: ChannelHandlerContext) {
		context.flush()
	}

	func errorCaught(context: ChannelHandlerContext, error: some Error) {
		print("error: \(error)")
		context.close(promise: nil)
	}
}
