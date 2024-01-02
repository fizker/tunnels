import Foundation
import Models
import WebSocketKit

enum WebSocketError: Error {
	case couldNotDecode(String)
}

extension WebSocket {
	public func onServerMessage(_ callback: @escaping (WebSocket, WebSocketServerMessage) async throws -> ()) {
		onMessage(callback)
	}

	public func onClientMessage(_ callback: @escaping (WebSocket, WebSocketClientMessage) async throws -> ()) {
		onMessage(callback)
	}

	private func onMessage<T: Decodable>(_ callback: @escaping (WebSocket, T) async throws -> ()) {
		onText { ws, value in
			do {
				let message: T = try decode(value)
				try await callback(ws, message)
			} catch let WebSocketError.couldNotDecode(message) {
				print("""
				Failed to decode message
				Error: \(message)
				Data: \(value)
				""")
			} catch {
				print("""
				Failed to handle message: \(error)
				Raw message:
				\(value)
				""")
			}
		}
	}

	public func send(_ message: WebSocketClientMessage) async throws {
		try await send(data: message)
	}

	public func send(_ message: WebSocketServerMessage) async throws {
		try await send(data: message)
	}

	private func send(data: some Encodable) async throws {
		let encoder = JSONEncoder()
		let json = try encoder.encode(data)
		try await send(String(data: json, encoding: .utf8)!)
	}
}

private func decode<T: Decodable>(_ value: String) throws -> T {
	guard let data = value.data(using: .utf8)
	else { throw WebSocketError.couldNotDecode("Invalid UTF-8") }

	let decoder = JSONDecoder()

	do {
		return try decoder.decode(T.self, from: data)
	} catch {
		throw WebSocketError.couldNotDecode(error.localizedDescription)
	}
}
