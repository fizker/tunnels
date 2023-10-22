import Foundation
import Models
import WebSocketKit

extension WebSocket {
	func onServerMessage(_ callback: @escaping (WebSocket, WebSocketServerMessage) async throws -> ()) {
		onText { ws, value in
			let data = value.data(using: .utf8)!
			let decoder = JSONDecoder()

			guard let message = try? decoder.decode(WebSocketServerMessage.self, from: data)
			else {
				print("Unknown message: \(value)")
				return
			}

			do {
				try await callback(ws, message)
			} catch {
				print("""
				Failed to handle message: \(error)
				Raw message:
				\(value)
				""")
			}
		}
	}

	func send(_ message: WebSocketClientMessage) async throws {
		let encoder = JSONEncoder()
		let json = try encoder.encode(message)
		try await send(String(data: json, encoding: .utf8)!)
	}
}
