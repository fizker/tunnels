import XCTest
import Binary

final class BitIteratorTests: XCTestCase {
	func test__next__backedByUInt8__returnsExpectedBits() async throws {
		let value: UInt8 = 0b00101100
		var iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertNil(iterator.next())
	}

	func test__next__backedByTwoUInt8__returnsExpectedBits() async throws {
		let firstValue: UInt8 = 0b00101100
		let secondValue: UInt8 = 0b01111100
		var iterator = BitIterator([ firstValue, secondValue ])

		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .zero)

		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .one)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(), .zero)

		XCTAssertNil(iterator.next())
	}

	func test__nextX__backedByUInt8__returnsExpectedValues() async throws {
		let value: UInt8 = 0b00101100
		var iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(2), 0b00)
		XCTAssertEqual(iterator.next(2), 0b10)
		XCTAssertEqual(iterator.next(2), 0b11)
		XCTAssertEqual(iterator.next(2), 0b00)
		XCTAssertNil(iterator.next(2))

		iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(3), 0b001)
		XCTAssertEqual(iterator.next(3), 0b011)
		// This overflows, which kills the rest of the values
		XCTAssertNil(iterator.next(3))
		XCTAssertNil(iterator.next())

		iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(3), 0b010)
		XCTAssertEqual(iterator.next(3), 0b110)
		// This overflows, which kills the rest of the values
		XCTAssertNil(iterator.next(3))
		XCTAssertNil(iterator.next())
	}

	func test__next8__backedByUInt32__returnsExpectedValues() async throws {
		let value: UInt32 = 0b00101100_01111100_00110100_00011110

		var iterator = BitIterator(value)
		XCTAssertEqual(iterator.next8(), 0b00101100)
		XCTAssertEqual(iterator.next8(), 0b01111100)
		XCTAssertEqual(iterator.next8(), 0b00110100)
		XCTAssertEqual(iterator.next8(), 0b00011110)
		XCTAssertNil(iterator.next8())

		iterator = BitIterator(value)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next8(), 0b01011000)
		XCTAssertEqual(iterator.next8(), 0b11111000)
		XCTAssertEqual(iterator.next8(), 0b01101000)
		XCTAssertNil(iterator.next8())
	}

	func test__next16__backedByUInt32__returnsExpectedValues() async throws {
		let value: UInt32 = 0b00101100_01111100_00110100_00011110

		var iterator = BitIterator(value)
		XCTAssertEqual(iterator.next16(), 0b00101100_01111100)
		XCTAssertEqual(iterator.next16(), 0b00110100_00011110)
		XCTAssertNil(iterator.next16())

		iterator = BitIterator(value)
		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next16(), 0b01011000_11111000)
		XCTAssertNil(iterator.next16())
	}
}
