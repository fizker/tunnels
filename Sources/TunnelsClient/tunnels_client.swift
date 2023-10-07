import AsyncHTTPClient
import Foundation
import Models
import NIO
import WebSocketKit

public func hello() async throws -> String {
	let client = HTTPClient()
	defer { _ = client.shutdown() }
	let response = try await client.get(url: "http://localhost:8110/hello")
	let body = try await response.body.collect(upTo: 1024 * 1024)
	return String(data: Data(buffer: body), encoding: .utf8) ?? ""
}

public func connect(id: UUID) async throws {
	let proxy = Proxy(localPort: 8080, remoteName: "example.com", remoteID: id)

	let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
	try await WebSocket.connect(to: "ws://localhost:8110/tunnels/\(id)", on: elg) { ws in
		ws.onText { ws, value in
			try? await handleText(proxy: proxy, ws: ws, value: value)
			print("From server: \(value)")
		}
	}.get()
}

func handleText(proxy: Proxy, ws: WebSocket, value: String) async throws {
	let data = value.data(using: .utf8)!
	let decoder = JSONDecoder()
	if let req = try? decoder.decode(HTTPRequest.self, from: data) {
		let res = await proxy.handle(req)
		let encoder = JSONEncoder()
		let json = try encoder.encode(res)
		try await ws.send(String(data: json, encoding: .utf8)!)
	}
}

extension HTTPClient {
	func get(url: String) async throws -> HTTPClientResponse {
		let request = HTTPClientRequest(url: url)
		return try await execute(request, timeout: .seconds(30))
	}
}
