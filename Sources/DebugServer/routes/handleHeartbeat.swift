import Vapor

@Sendable
func handleHeartbeat(req: Request) -> Response {
	let interval = req.query["interval"].flatMap(Int.init(_:)) ?? 3

	return .init(html: """
	<!doctype html>
	<div>Counter is 1</div>

	<script>
		const div = document.querySelector("div")
		let counter = 1
		setInterval(async () => {
			const response = await fetch("/ping?count=" + counter)
			counter = await response.json()
			div.innerText = "Counter is " + counter
		}, \(interval)_000)
	</script>
	""")
}
