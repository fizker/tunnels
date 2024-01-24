/// This is a basic test server for receiving any request and logging the response.

const http = require('http')
const { pipeline } = require('node:stream/promises')

const port = process.env.PORT ?? 8080

const server = http.createServer(async (req, res) => {
	const url = new URL(req.url, `http://${req.headers.host}`)
	const { method, headers } = req
	const body = await readBody(req)
	console.log({ url, method, headers, body })

	if(url.pathname.startsWith('/redirect')) {
		res.statusCode = 302
		const location = url.searchParams.get('location')
		res.setHeader('location', location ?? '/after-redirect')
		res.end()
		return
	}

	if(url.pathname.startsWith("/ping")) {
		const counter = +(url.searchParams.get("count") ?? 1)
		res.statusCode = 200
		res.setHeader("content-type", "text/plain")
		res.end(`${counter + 1}`)
		return
	}

	if(url.pathname.startsWith("/heartbeat")) {
		getHeartbeat(req, res, url)
		return
	}

	res.statusCode = 200
	res.setHeader('Content-Type', 'text/plain')
	res.setHeader('set-cookie', [
		'first=cookie',
		'second=cookie',
	])

	const response = 'Hello World at ' + req.url
	if(headers['x-include-content-length']) {
		res.end(response)
	} else {
		res.write(response)
		res.end()
	}
})

server.listen(port, () => {
	console.log(`Server running at port ${port}`)
})

async function readBody(req) {
	if(!req.headers['content-type']) {
		return null
	}

	let content = ''
	await pipeline(req, async function* (source) {
		source.setEncoding('utf8')
		for await (const chunk of source) {
			content += chunk
			yield
		}
	})

	return content
}

function getHeartbeat(req, res, url) {
	const interval = url.searchParams.get("interval") ?? 3
	res.statusCode = 200
	res.setHeader("content-type", "text/html")
	res.end(`<!doctype html>
	<div>Counter is 1</div>
	<script>
	const div = document.querySelector("div")
	let counter = 1
	setInterval(async () => {
		const response = await fetch("/ping?count=" + counter)
		counter = await response.json()
		div.innerText = "Counter is " + counter
	}, ${interval}000)
	</script>`)
}
