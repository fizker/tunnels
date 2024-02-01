import Vapor

@Sendable
func catchAll(req: Request) -> Response {
	let includeContentLength = req.headers.first(name: "x-include-content-length") == "true"

	let body = "Hello World at \(req.url)"

	return Response(
		status: .ok,
		headers: HTTPHeaders([
			("Content-Type", "text/plain"),
			("set-cookie", "first=cookie"),
			("set-cookie", "second=cookie"),
		]),
		body: includeContentLength
			? .init(string: body)
			: .init(stream: { writer in
				_ = writer.write(.buffer(.init(string: body)))
				.map { _ in
					writer.write(.end)
				}
			})
	)
}
