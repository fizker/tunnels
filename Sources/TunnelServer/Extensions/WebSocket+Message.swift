import Foundation
import Models
import WebSocketKit

extension WebSocket {
	func onClientMessage(_ callback: @escaping (WebSocket, WebSocketClientMessage) async throws -> ()) {
		onText { ws, value in
			let data = value.data(using: .utf8)!
			let decoder = JSONDecoder()

			guard let message = try? decoder.decode(WebSocketClientMessage.self, from: data)
			else {
				print("Unknown message: \(value)")
				return
			}

			do {
				try await callback(ws, message)
			} catch {
				print("Failed to handle client message: \(error)")
			}
		}
	}

	func send(_ message: WebSocketServerMessage) async throws {
		let encoder = JSONEncoder()
		let json = try encoder.encode(message)
		try await send(String(data: json, encoding: .utf8)!)
	}
}
