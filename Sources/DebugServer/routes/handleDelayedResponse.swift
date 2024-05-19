import Vapor

@Sendable
func handleDelayedResponse(req: Request) async -> Response {
	let delay = req.query["delay"].flatMap(Int.init(_:)) ?? 45
	let forceExit = req.query["force-exit"].flatMap(Bool.init(_:)) ?? false

	for i in 1...delay {
		try? await Task.sleep(for: .seconds(1))
		req.logger.info("Countdown until response: \(i)s of \(delay)s")
	}

	if forceExit {
		exit(0)
	}

	return Response(html: """
	<!doctype html>

	<p>Wait over</p>
	""")
}
