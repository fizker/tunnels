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
}
