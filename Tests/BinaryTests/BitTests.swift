import XCTest
@testable import Binary

final class BitTests: XCTestCase {
	func test__initWithBinaryInteger__valueIsUInt8_positionIsValid__correctBitValueReturned() async throws {
		let value: UInt8 = 0b01010110

		XCTAssertEqual(Bit(value, at: 7), .zero)
		XCTAssertEqual(Bit(value, at: 6), .one)
		XCTAssertEqual(Bit(value, at: 5), .zero)
		XCTAssertEqual(Bit(value, at: 4), .one)
		XCTAssertEqual(Bit(value, at: 3), .zero)
		XCTAssertEqual(Bit(value, at: 2), .one)
		XCTAssertEqual(Bit(value, at: 1), .one)
		XCTAssertEqual(Bit(value, at: 0), .zero)
	}
}
