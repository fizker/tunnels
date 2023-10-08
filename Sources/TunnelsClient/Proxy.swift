import AsyncHTTPClient
import Foundation
import Models
import NIO
import WebSocketKit

public class Proxy {
	var localPort: Int
	var remoteName: String
	var remoteID: UUID

	var webSocket: WebSocket?

	public init(localPort: Int, remoteName: String = "", remoteID: UUID) {
		self.localPort = localPort
		self.remoteName = remoteName
		self.remoteID = remoteID
	}

	public func connect() async throws {
		let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
		webSocket = try await withCheckedThrowingContinuation { continuation in
			WebSocket.connect(to: "ws://localhost:8110/tunnels/\(remoteID)", on: elg) { ws in
				continuation.resume(returning: ws)
			}.whenFailure { error in
				continuation.resume(throwing: error)
			}
		}

		webSocket?.onText { [weak self] ws, value in
			try? await self?.handleText(value: value)
			print("From server: \(value)")
		}
	}

	public func waitUntilClose() async throws {
		guard let webSocket
		else { return }

		try await withCheckedThrowingContinuation { continuation in
			webSocket.onClose.whenComplete {
				continuation.resume(with: $0)
			}
		}
	}

	func handleText(value: String) async throws {
		let data = value.data(using: .utf8)!
		let decoder = JSONDecoder()
		if let req = try? decoder.decode(HTTPRequest.self, from: data) {
			let res = try await handle(req)
			let encoder = JSONEncoder()
			let json = try encoder.encode(res)
			try await webSocket?.send(String(data: json, encoding: .utf8)!)
		}
	}

	func handle(_ req: HTTPRequest) async throws -> HTTPResponse {
		var request = HTTPClientRequest(url: "http://localhost:\(localPort)\(req.url)")
		request.method = .RAW(value: req.method)
		request.headers = .init(req.headers.map { ($0, $1.joined(separator: " ")) })
		request.body = switch req.body {
		case let .text(text):
			.bytes(text.data(using: .utf8)!)
		case let .binary(data):
			.bytes(data)
		case nil:
			nil
		}

		let client = HTTPClient()
		let response = try await client.execute(request, timeout: .seconds(30))
		let res = try await HTTPResponse(id: req.id, response: response)
		try await client.shutdown()

		return res
	}

	private func body(for response: HTTPClientResponse) async throws -> HTTPBody? {
		guard
			let type = response.headers.first(name: "content-type")?.lowercased(),
			let length = response.headers.first(name: "content-length").flatMap(Int.init)
		else { return nil }

		var rawContent = try await response.body.collect(upTo: length)
		let content = rawContent.readData(length: length)!
		if type.starts(with: "text/") || type.starts(with: "application/json") {
			return .text(String(data: content, encoding: .utf8)!)
		} else {
			return .binary(content)
		}
	}
}
