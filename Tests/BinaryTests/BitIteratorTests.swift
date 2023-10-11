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

		XCTAssertEqual(iterator.next(2), 0)
		XCTAssertEqual(iterator.next(2), 2)
		XCTAssertEqual(iterator.next(2), 3)
		XCTAssertEqual(iterator.next(2), 0)
		XCTAssertNil(iterator.next(2))

		iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(3), 1)
		XCTAssertEqual(iterator.next(3), 3)
		// This overflows, which kills the rest of the values
		XCTAssertNil(iterator.next(3))
		XCTAssertNil(iterator.next())

		iterator = BitIterator(value)

		XCTAssertEqual(iterator.next(), .zero)
		XCTAssertEqual(iterator.next(3), 2)
		XCTAssertEqual(iterator.next(3), 6)
		// This overflows, which kills the rest of the values
		XCTAssertNil(iterator.next(3))
		XCTAssertNil(iterator.next())
	}
}
