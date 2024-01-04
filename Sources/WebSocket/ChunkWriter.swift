import Binary
import Foundation
import NIOCore

struct ChunkWriter {
	var id: UUID
	var chunks: [BitIterator]

	init(id: UUID = UUID(), data: Data, maxChunkSize: Int) {
		self.id = id

		// 16 for UUID, 2 for each index
		let firstChunkSize = maxChunkSize - 20

		let dataSize = data.count

		guard dataSize > firstChunkSize
		else {
			chunks = [Self.add(id: id, chunkIndex: 0, chunkCount: 1, to: data)]
			return
		}

		// 16 for UUID, 2 for the index
		let subsequentChunkSize = maxChunkSize - 18

		var currentIndex = 0
		var nextIndex = firstChunkSize

		let chunk = data[currentIndex ..< nextIndex]
		chunks = [BitIterator(1 as UInt8)]

		currentIndex = nextIndex
		nextIndex += subsequentChunkSize

		while nextIndex < dataSize {
			let chunk = data[currentIndex ..< nextIndex]
			let n = Self.add(id: id, chunkIndex: UInt16(chunks.count), to: chunk)
			chunks.append(n)
			currentIndex = nextIndex
			nextIndex += subsequentChunkSize
		}

		let n = Self.add(id: id, chunkIndex:  UInt16(chunks.count), to: data[currentIndex...])
		chunks.append(n)

		chunks[0] = Self.add(id: id, chunkIndex: 0, chunkCount:  UInt16(chunks.count), to: chunk)
	}

	static func add(id: UUID, chunkIndex: UInt16, chunkCount: UInt16? = nil, to data: Data) -> BitIterator {
		var b: ByteBuffer = .init()
		b.writeUUIDBytes(id)
		b.writeBytes(chunkIndex.asUInt8)
		if let chunkCount {
			b.writeBytes(chunkCount.asUInt8)
		}
		b.writeBytes(data)
		return .init(b.readableBytesView)
	}
}

extension ChunkWriter: Sequence {
	typealias Element = Data
	typealias Iterator = Array<Data>.Iterator

	func makeIterator() -> Array<Data>.Iterator {
		chunks.compactMap {
			var chunk = $0
			return chunk.data()
		}.makeIterator()
	}
}
