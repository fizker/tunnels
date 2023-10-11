import XCTest
@testable import Binary

final class BitTests: XCTestCase {
	func test__initWithBinaryInteger__valueIsUInt8_positionIsValid__correctBitValueReturned() async throws {
		let value: UInt8 = 0b01010110

		XCTAssertEqual(Bit(value, position: 7), .zero)
		XCTAssertEqual(Bit(value, position: 6), .one)
		XCTAssertEqual(Bit(value, position: 5), .zero)
		XCTAssertEqual(Bit(value, position: 4), .one)
		XCTAssertEqual(Bit(value, position: 3), .zero)
		XCTAssertEqual(Bit(value, position: 2), .one)
		XCTAssertEqual(Bit(value, position: 1), .one)
		XCTAssertEqual(Bit(value, position: 0), .zero)
	}

	func test__initWithBinaryIntegerFromLeft__valueIsUInt8_positionIsValid__correctBitValueReturned() async throws {
		let value: UInt8 = 0b01010110

		XCTAssertEqual(Bit(value, positionFromMostSignificant: 0), .zero)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 1), .one)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 2), .zero)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 3), .one)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 4), .zero)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 5), .one)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 6), .one)
		XCTAssertEqual(Bit(value, positionFromMostSignificant: 7), .zero)
	}
}
