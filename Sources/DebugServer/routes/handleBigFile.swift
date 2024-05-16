import Common
import Crypto
import Vapor

@Sendable
func handleBigFile(req: Request) async -> Response {
	let size = req.query["size"].flatMap(Int.init(_:)) ?? 1_000_000

	let digest = await SHA256.digest(stream: AsyncStream(generateDataStreamOfSize: size))

	req.logger.info("Creating big file with digest \(digest)")

	return Response(
		headers: [
			"x-digest-value": digest.hex,
			"x-digest-alg": "sha256",
			"content-type": "text/plain",
		],
		body: .init(stream: { writer in
		Task {
			for await next in AsyncStream(generateDataStreamOfSize: size) {
				let buffer = ByteBuffer(data: next)
				try await writer.write(.buffer(buffer)).get()
			}
			try await writer.write(.end).get()
		}
	}))
}
