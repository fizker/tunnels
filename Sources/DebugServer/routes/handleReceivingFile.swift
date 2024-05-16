import Common
import Crypto
import Vapor

/// Checks the sent file against the given digest.
///
/// - Required query parameters: `digest`
@Sendable
func handleReceivingFile(req: Request) async throws -> Response {
	guard let digest = req.query["digest"] as String?
	else {
		req.logger.info("Failing request because digest query is missing")
		return Response(status: .badRequest, body: "Invalid request. digest query is required")
	}

	let rawBody = try await req.body.collectAll(as: [ByteBuffer].self)
	let body = rawBody.reduce(into: ByteBuffer()) { partialResult, buffer in
		var buffer = buffer
		partialResult.writeBuffer(&buffer)
	}

	guard body.readableBytes > 0
	else {
		req.logger.info("Failing request because body is missing")
		return Response(status: .badRequest, body: "A body is required")
	}

	let actualDigest = SHA256.hash(data: body.readableBytesView)

	let isMatch = digest == actualDigest.hex

	return Response(
		headers: [
			"content-type": "text/plain",
		],
		body: isMatch ? "Content received correctly" : "Incorrect body received"
	)
}
