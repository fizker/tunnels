import Crypto
import Vapor

let chunkSize = 1024
let a = Character("a").asciiValue!

@Sendable
func handleBigFile(req: Request) async -> Response {
	let size = req.query["size"].flatMap(Int.init(_:)) ?? 1_000_000

	var digester = SHA256()
	for await next in data(size: size) {
		digester.update(data: next)
	}
	let digest = digester.finalize()

	req.logger.info("Creating big file with digest \(digest)")

	return Response(
		headers: [
			"x-digest-value": digest.hex,
			"x-digest-alg": "sha256",
			"content-type": "text/plain",
		],
		body: .init(stream: { writer in
		Task {
			for await next in data(size: size) {
				let buffer = ByteBuffer(data: next)
				try await writer.write(.buffer(buffer)).get()
			}
			try await writer.write(.end).get()
		}
	}))
}

func data(size: Int) -> AsyncStream<Data> {
	AsyncStream { writer in
		var remainder = size
		for _ in stride(from: 0, to: size, by: chunkSize) {
			let toWrite = min(remainder, chunkSize)
			remainder -= toWrite
			writer.yield(Data(repeating: a, count: toWrite))
		}
		if remainder > 0 {
			writer.yield(Data(repeating: a, count: remainder))
		}
		writer.finish()
	}
}
