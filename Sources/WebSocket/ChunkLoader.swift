import Binary
import Foundation

struct ChunkLoader {
	enum Error: Swift.Error {
		case idMissing
	}

	private var id: UUID

	private var started: Date = .now

	private var expectedCount: UInt16?
	private var currentCount: UInt16 = 0
	var chunks: [UInt16: BitIterator] = [:]

	init(id: UUID) {
		self.id = id
	}

	mutating func add(_ chunk: BitIterator) throws {
		var chunk = chunk
		guard let idx = chunk.next16()
		else { throw Error.idMissing }

		if idx == 0 {
			expectedCount = chunk.next16()
		}

		chunks[idx] = chunk

		currentCount += 1
	}

	var data: Data? {
		guard isComplete
		else { return nil }

		let capacity = chunks.values.reduce(0) { partialResult, chunk in
			partialResult + chunk.remainingBytes
		}
		var data = Data(capacity: capacity)
		for idx in 0..<currentCount {
			guard let chunk = chunks[idx]
			else {
				assert(false, "Chunk was not loaded. `isComplete` must be bugged.")
				return nil
			}
			data.append(contentsOf: chunk.byteSequence)
		}
		return data
	}

	var isComplete: Bool { currentCount == expectedCount }
	func isTimedOut(timeOut: Duration = .seconds(30)) -> Bool {
		let expiration = started.addingTimeInterval(timeOut.asTimeInterval)
		let now = Date.now

		return now < expiration
	}
}

extension Duration {
	var asTimeInterval: TimeInterval {
		let (seconds, attoseconds) = components
		let milliseconds = Double(attoseconds / 1_000_000_000_000_000)
		return Double(seconds) + milliseconds / 1000
	}
}
