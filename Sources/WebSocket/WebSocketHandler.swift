import Foundation
import Models
import WebSocketKit

enum WebSocketError: Error {
	case couldNotDecode(String)
}

public actor WebSocketHandler {
	public let webSocket: WebSocket
	var chunkLoaders: [UUID: ChunkLoader] = [:]

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
		webSocket.onBinary { [weak self] ws, value in
			guard let self
			else { return }

			do {
				guard let message: T = try await decode(value)
				else { return }
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

		let chunks = ChunkWriter(data: json, maxChunkSize: 1 << 14)

		for chunk in chunks {
			try await webSocket.send(raw: chunk, opcode: .binary)
		}
	}

	/// Decodes the buffer, combining chunks as necessary.
	///
	/// If the buffer is part of a chunked message, it will return `nil` until all the chunks are received.
	private func decode<T: Decodable>(_ value: ByteBuffer) throws -> T? {
		var value = value

		guard let id = value.readUUIDBytes()
		else { throw WebSocketError.couldNotDecode("ID is missing") }

		var chunkLoader = chunkLoaders.removeValue(forKey: id) ?? ChunkLoader(id: id)
		try chunkLoader.add(value.readableBytesView.makeBitIterator())

		guard let data = chunkLoader.data
		else {
			chunkLoaders[id] = chunkLoader
			return nil
		}

		let decoder = JSONDecoder()

		do {
			return try decoder.decode(T.self, from: data)
		} catch {
			throw WebSocketError.couldNotDecode(error.localizedDescription)
		}
	}
}
