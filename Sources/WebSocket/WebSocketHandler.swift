import Foundation
import Models
import WebSocketKit

enum WebSocketError: Error {
	case couldNotDecode(String)
}

public actor WebSocketHandler {
	public let webSocket: WebSocket

	public init(webSocket: WebSocket) {
		self.webSocket = webSocket
	}

	public func close() async throws {
		try await webSocket.close()
	}

	public nonisolated func onServerMessage(_ callback: @escaping (WebSocket, WebSocketServerMessage) async throws -> ()) {
		onMessage(callback)
	}

	public nonisolated func onClientMessage(_ callback: @escaping (WebSocket, WebSocketClientMessage) async throws -> ()) {
		onMessage(callback)
	}

	private nonisolated func onMessage<T: Decodable>(_ callback: @escaping (WebSocket, T) async throws -> ()) {
		webSocket.onBinary { ws, value in
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
		try await webSocket.send(Array(json))
	}
}

private func decode<T: Decodable>(_ value: ByteBuffer) throws -> T {
	var value = value
	guard let data = value.readData(length: value.readableBytes)
	else { throw WebSocketError.couldNotDecode("Invalid ByteBuffer") }

	let decoder = JSONDecoder()

	do {
		return try decoder.decode(T.self, from: data)
	} catch {
		throw WebSocketError.couldNotDecode(error.localizedDescription)
	}
}
