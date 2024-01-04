import Binary
import XCTest
@testable import WebSocket

final class ChunkWriterTests: XCTestCase {
	let uuidBytes: [UInt8] = [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	let uuid = UUID(uuid: (1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

	/// The header of the first chunk is 20 bytes, leaving 4 for the test value
	///
	/// Subsequent chunks have a header size of 18 bytes.
	let maxChunkSize = 24

	func test__initWithData__dataIsSmallerThanChunkSize__containsOneChunk() async throws {
		let data = Data([
			0xde, 0xad,
			0xbe, 0xef,
		])

		let writer = ChunkWriter(id: uuid, data: data, maxChunkSize: maxChunkSize)

		var iterator = writer.chunks.makeIterator()
		var chunk = iterator.next()
		XCTAssertEqual(chunk?.data(), self.chunk(index: 0, count: 1, data: data))

		XCTAssertNil(iterator.next())
	}

	func test__initWithData__dataRequiresTwoChunks_exactFit__containsExpectedChunks() async throws {
		let data = Data([
			0xde, 0xad,
			0xbe, 0xef,

			0xaa, 0xbb,
			0xcc, 0xdd,
			0xee, 0xff,
		])

		let writer = ChunkWriter(id: uuid, data: data, maxChunkSize: maxChunkSize)

		var iterator = writer.chunks.makeIterator()

		var chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 0, count: 2, data: Data([
			0xde, 0xad,
			0xbe, 0xef,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 1, data: Data([
			0xaa, 0xbb,
			0xcc, 0xdd,
			0xee, 0xff,
		])))

		XCTAssertNil(iterator.next())
	}

	func test__initWithData__dataRequiresTwoChunks_lastChunkIsPartial__containsExpectedChunks() async throws {
		let data = Data([
			0xde, 0xad,
			0xbe, 0xef,

			0xaa, 0xbb,
			0xcc, 0xdd,
		])

		let writer = ChunkWriter(id: uuid, data: data, maxChunkSize: maxChunkSize)

		var iterator = writer.chunks.makeIterator()

		var chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 0, count: 2, data: Data([
			0xde, 0xad,
			0xbe, 0xef,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 1, data: Data([
			0xaa, 0xbb,
			0xcc, 0xdd,
		])))

		XCTAssertNil(iterator.next())
	}

	func test__initWithData__dataRequiresMultipleChunks_exactFit__containsExpectedChunks() async throws {
		let data = Data([
			0x01, 0x02,
			0x03, 0x04,

			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,

			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,

			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,
		])

		let writer = ChunkWriter(id: uuid, data: data, maxChunkSize: maxChunkSize)

		var iterator = writer.chunks.makeIterator()
		var chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 0, count: 4, data: Data([
			0x01, 0x02,
			0x03, 0x04,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 1, data: Data([
			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 2, data: Data([
			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 3, data: Data([
			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,
		])))

		XCTAssertNil(iterator.next())
	}

	func test__initWithData__dataRequiresMultipleChunks_lastChunkIsPartial__containsExpectedChunks() async throws {
		let data = Data([
			0x01, 0x02,
			0x03, 0x04,

			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,

			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,

			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,

			0x41, 0x42,
		])

		let writer = ChunkWriter(id: uuid, data: data, maxChunkSize: maxChunkSize)

		var iterator = writer.chunks.makeIterator()
		var chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 0, count: 5, data: Data([
			0x01, 0x02,
			0x03, 0x04,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 1, data: Data([
			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 2, data: Data([
			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 3, data: Data([
			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,
		])))

		chunk = iterator.next()
		assertEqual(chunk?.data(), self.chunk(index: 4, data: Data([
			0x41, 0x42,
		])))

		XCTAssertNil(iterator.next())
	}

	func assertEqual(_ first: Data?, _ second: Data?, file: StaticString = #filePath, line: UInt = #line) {
		XCTAssertEqual(first, second, "\(first?.hexEncodedString() ?? "nil") -> \(second?.hexEncodedString() ?? "nil")", file: file, line: line)
	}

	func chunk(index: UInt16, count: UInt16? = nil, data: Data) -> Data {
		var output = Data(uuidBytes)
		output.append(contentsOf: index.asUInt8)
		if let count {
			output.append(contentsOf: count.asUInt8)
		}
		output.append(data)
		return output
	}
}

extension Data {
	struct HexEncodingOptions: OptionSet {
		let rawValue: Int
		static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
	}

	func hexEncodedString(options: HexEncodingOptions = []) -> String {
		let hexDigits = options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef"

		let utf8Digits = Array(hexDigits.utf8)
		return String(unsafeUninitializedCapacity: 2 * count) { (ptr) -> Int in
			var p = ptr.baseAddress!
			for byte in self {
				p[0] = utf8Digits[Int(byte / 16)]
				p[1] = utf8Digits[Int(byte % 16)]
				p += 2
			}
			return 2 * count
		}
	}
}
