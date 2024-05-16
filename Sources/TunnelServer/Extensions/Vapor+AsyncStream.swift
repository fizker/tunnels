import Vapor

extension Request.Body {
	func stream(on eventLoop: any EventLoop, onFinish: @escaping @Sendable ((any Error)?) -> Void) -> AsyncThrowingStream<UInt8, any Error> {
		return .init { c in
			drain { (body: BodyStreamResult) in
				switch body {
				case .end:
					c.finish()
					onFinish(nil)
				case let .error(error):
					c.finish(throwing: error)
					onFinish(error)
				case let .buffer(buffer):
					let d = Data(buffer: buffer)
					for byte in d {
						c.yield(byte)
					}
				}

				return eventLoop.future()
			}
		}
	}
}

extension Response.Body {
	init(stream: AsyncStream<UInt8>, bufferSize: Int = 1024) {
		self.init(stream: AsyncThrowingStream { continuation in
			Task {
				for await value in stream {
					continuation.yield(value)
				}
				continuation.finish()
			}
		})
	}

	init(stream: AsyncThrowingStream<UInt8, any Error>, bufferSize: Int = 1024) {
		self.init(stream: { writer in
			Task {
				do {
					var buffer = ByteBuffer()
					for try await byte in stream {
						buffer.writeInteger(byte)
						if buffer.readableBytes >= bufferSize {
							try await writer.write(.buffer(buffer))
							buffer.clear()
						}
					}

					if buffer.readableBytes > 0 {
						try await writer.write(.buffer(buffer))
					}
				} catch {
					try await writer.write(.error(error))
				}
				try await writer.write(.end)
			}
		})
	}
}

extension BodyStreamWriter {
	func write(_ result: BodyStreamResult) async throws {
		try await write(result).get()
	}
}
