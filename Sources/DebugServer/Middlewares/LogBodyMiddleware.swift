import Vapor

struct LogBodyMiddleware: Middleware {
	func respond(to req: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
		if let body = req.body.string {
			req.logger.info("""
			Received body at \(req.method) http://\(req.headers.first(name: "host") ?? "localhost")\(req.url):
			\(body)
			""")
		}

		return next.respond(to: req)
	}
}
