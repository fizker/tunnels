import Vapor

@Sendable
func handlePing(req: Request) -> Response {
	let counter = req.query["count"].flatMap(Int.init(_:)) ?? 0
	return Response(
		headers: [
			"content-type": "text/plain",
		],
		body: .init(string: "\(counter + 1)")
	)
}
