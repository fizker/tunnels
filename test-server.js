/// This is a basic test server for receiving any request and logging the response.

const http = require('http')
const { pipeline } = require('node:stream/promises')

const port = process.env.PORT ?? 8080

const server = http.createServer(async (req, res) => {
	const { url, method, headers } = req
	const body = await readBody(req)
	console.log({ url, method, headers, body })

	if(url.startsWith('/redirect')) {
		res.statusCode = 302
		const u = new URL(url, `http://${req.headers.host}`)
		const location = u.searchParams.get('location')
		res.setHeader('location', location ?? '/after-redirect')
		res.end()
		return
	}

	res.statusCode = 200
	res.setHeader('Content-Type', 'text/plain')
	res.end('Hello World at ' + req.url)
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
