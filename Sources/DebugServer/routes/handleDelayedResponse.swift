import Vapor

@Sendable
func handleDelayedResponse(req: Request) async -> Response {
	let delay = req.query["delay"].flatMap(Int.init(_:)) ?? 45
	let forceExit = req.query["force-exit"].flatMap(Bool.init(_:)) ?? false

	if req.query["form"] == "true" {
		return htmlForm(delay: delay, forceExit: forceExit, req: req)
	}

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

func htmlForm(delay: Int, forceExit: Bool, req: Request) -> Response {
	let concurrent = req.query["concurrent"].flatMap(Int.init(_:)) ?? 1
	let host = req.query["host"] ?? ""

	return Response(html: """
	<!doctype html>

	<script>
		function handle(event, form) {
			const concurrent = +form.concurrent.value
			if(concurrent == 1) return

			event.preventDefault()
			const params = new URLSearchParams()
			params.append("delay", form.delay.value)
			if(form['force-exit'].checked) {
				params.append("force-exit", "true")
			}
			const url = form.action + '?' + params.toString()
			const results = []
			const start = Date.now()
			const result = document.querySelector("#result")
			for(let i = 0; i < concurrent; i++) {
				const promise = fetch(url)
				promise.then(() => {
					const now = Date.now()
					results.push({ time: now - start })
					update()
				})
			}
			update()

			function update() {
				result.innerHTML = `<ul>${results.map((x, idx) => `<li>${idx+1}: ${x.time} ms`).join("")}</ul>`
				const remaining = concurrent - results.length
				result.innerHTML += remaining == 0 ? `All done` : `${remaining} left`
			}
		}
	</script>

	<form action=\(host)/delayed onsubmit="handle(event, this)">
		<label>Delay: <input name="delay" type=number value="\(delay)">s</label>
		<label>Force exit: <input type=checkbox name="force-exit" \(forceExit ? "checked" : "")></label>
		<label>Concurrent calls: <input name=concurrent type=number value="\(concurrent)" min=1></label>
		<button>Start</button>
	</form>
	<div id="result">
	""")
}
