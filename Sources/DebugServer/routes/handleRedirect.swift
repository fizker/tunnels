import Vapor

@Sendable
func handleRedirect(req: Request) -> Response {
	let location = req.query["location"] ?? "/after-redirect"
	return req.redirect(to: location, redirectType: .temporary)
}
