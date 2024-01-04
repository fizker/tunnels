import Binary
import XCTest
@testable import WebSocket

final class ChunkLoaderTests: XCTestCase {
	func test__add__singleChunk__loaderIsComplete() async throws {
		let data = Data([
			0xde, 0xad,
			0xbe, 0xef,
		])

		var chunkLoader = ChunkLoader(id: UUID())
		try chunkLoader.add(chunk(index: 0, count: 1, data: data))

		XCTAssertTrue(chunkLoader.isComplete)
		assertEqual(chunkLoader.data, data)
	}

	func test__add__twoChunks_chunksAreInOrder__loaderIsComplete() async throws {
		let data1 = Data([
			0xde, 0xad,
			0xbe, 0xef,
		])

		let data2 = Data([
			0xaa, 0xbb,
			0xcc, 0xdd,
			0xee, 0xff,
		])

		var chunkLoader = ChunkLoader(id: UUID())
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 0, count: 2, data: data1))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 1, data: data2))
		XCTAssertTrue(chunkLoader.isComplete)

		assertEqual(chunkLoader.data, data1 + data2)
	}

	func test__add__multipleChunks_chunksAreInOrder__loaderIsComplete() async throws {
		let data0 = Data([
			0x01, 0x02,
			0x03, 0x04,
		])

		let data1 = Data([
			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,
		])

		let data2 = Data([
			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,
		])

		let data3 = Data([
			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,
		])

		var chunkLoader = ChunkLoader(id: UUID())
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 0, count: 4, data: data0))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 1, data: data1))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 2, data: data2))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 3, data: data3))
		XCTAssertTrue(chunkLoader.isComplete)
		assertEqual(chunkLoader.data, data0 + data1 + data2 + data3)
	}

	func test__add__multipleChunks_chunksAreOutOfOrder__loaderIsComplete() async throws {
		let data0 = Data([
			0x01, 0x02,
			0x03, 0x04,
		])

		let data1 = Data([
			0x11, 0x12,
			0x13, 0x14,
			0x15, 0x16,
		])

		let data2 = Data([
			0x21, 0x22,
			0x23, 0x24,
			0x25, 0x26,
		])

		let data3 = Data([
			0x31, 0x32,
			0x33, 0x34,
			0x35, 0x36,
		])

		var chunkLoader = ChunkLoader(id: UUID())
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 1, data: data1))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 3, data: data3))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 0, count: 4, data: data0))
		XCTAssertFalse(chunkLoader.isComplete)

		try chunkLoader.add(chunk(index: 2, data: data2))
		XCTAssertTrue(chunkLoader.isComplete)

		assertEqual(chunkLoader.data, data0 + data1 + data2 + data3)
	}

	func chunk(index: UInt16, count: UInt16? = nil, data: Data) -> BitIterator {
		var output = Data()
		output.append(contentsOf: index.asUInt8)
		if let count {
			output.append(contentsOf: count.asUInt8)
		}
		output.append(data)
		return .init(output)
	}

	func assertEqual(_ first: Data?, _ second: Data?, file: StaticString = #filePath, line: UInt = #line) {
		XCTAssertEqual(first, second, "\(first?.hexEncodedString() ?? "nil") -> \(second?.hexEncodedString() ?? "nil")", file: file, line: line)
	}
}
