import Vapor

@Sendable
func handleCustomHTTPStatus(req: Request) -> Response {
	let statusCode = Int(req.query["status"] ?? "200") ?? 200
	return Response(status: .init(statusCode: statusCode))
}
