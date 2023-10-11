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

		XCTAssertEqual(Bit(value, positionFromLeft: 0), .zero)
		XCTAssertEqual(Bit(value, positionFromLeft: 1), .one)
		XCTAssertEqual(Bit(value, positionFromLeft: 2), .zero)
		XCTAssertEqual(Bit(value, positionFromLeft: 3), .one)
		XCTAssertEqual(Bit(value, positionFromLeft: 4), .zero)
		XCTAssertEqual(Bit(value, positionFromLeft: 5), .one)
		XCTAssertEqual(Bit(value, positionFromLeft: 6), .one)
		XCTAssertEqual(Bit(value, positionFromLeft: 7), .zero)
	}
}
