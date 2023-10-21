import Binary
import NIO

typealias HostMap = [String: ResourceRecord.Data]

private let cloudflareAddress = try! SocketAddress(ipAddress: "1.1.1.1", port: 53)

class DNSServer {
	var port: Int
	var channel: Channel!
	var hostMap: HostMap
	var dnsProxyAddress: SocketAddress

	/// The key is the DNSPacket ID, and the value is the address of the original sender, that should get the response
	var pendingProxyRequests: [UInt16: SocketAddress] = [:]

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
				$0.pipeline.addHandler(self)
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

extension DNSServer: ChannelInboundHandler {
	typealias InboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = AddressedEnvelope<ByteBuffer>

	func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let addressedEnvelope = unwrapInboundIn(data)
		let input = addressedEnvelope

		print("Received message from \(input.remoteAddress)")

		var iterator = addressedEnvelope.data.readableBytesView.makeBitIterator()
		do {
			let packet = try DNSPacket(iterator: &iterator)

			if packet.header.kind == .response {
				guard let remoteAddress = pendingProxyRequests[packet.header.id]
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

	func channelReadComplete(context: ChannelHandlerContext) {
		context.flush()
	}

	func errorCaught(context: ChannelHandlerContext, error: Error) {
		print("error: \(error)")
		context.close(promise: nil)
	}
}
