import Binary
import NIO

typealias HostMap = [String: ResourceRecord.Data]

class DNSServer {
	var port: Int
	var channel: Channel?
	var hostMap: HostMap

	public init(port: Int = 53, hostMap: HostMap) {
		self.port = port
		self.hostMap = hostMap
	}

	public func connect() async throws {
		let hostMap = hostMap

		let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
		let bootstrap = DatagramBootstrap(group: group)
			.channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
			.channelInitializer {
				$0.pipeline.addHandler(QueryPacketHandler(hostMap: hostMap))
			}

		channel = try await bootstrap.bind(host: "0.0.0.0", port: port).get()
	}

	public func waitUntilClose() async throws {
		try await channel?.closeFuture.get()
	}
}

class QueryPacketHandler: ChannelInboundHandler {
	typealias InboundIn = AddressedEnvelope<ByteBuffer>
	typealias OutboundOut = AddressedEnvelope<ByteBuffer>

	var hostMap: HostMap

	init(hostMap: HostMap) {
		self.hostMap = hostMap
	}

	func channelRead(context: ChannelHandlerContext, data: NIOAny) {
		let addressedEnvelope = unwrapInboundIn(data)
		let input = addressedEnvelope

		print("Received message from \(input.remoteAddress)")

		var iterator = addressedEnvelope.data.readableBytesView.makeBitIterator()
		do {
			let packet = try DNSPacket(iterator: &iterator)

			guard packet.header.kind == .query
			else { throw ParseError.notQuery }

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
			iterator.bitIndex = 0
			let header = Header(iterator: &iterator)

			let response = DNSPacket(header: Header(
				id: header?.id ?? 0,
				kind: .response,
				opcode: .query,
				isAuthoritativeAnswer: false,
				isTruncated: false,
				isRecursionDesired: false,
				isRecursionAvailable: false,
				z: 0,
				responseCode: .formatError,
				questionCount: 0,
				answerCount: 0,
				authorityCount: 0,
				additionalCount: 0
			), questions: [], answers: [])
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
