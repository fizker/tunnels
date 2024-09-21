import Testing
@testable import Binary

struct BitTests {
	@Test
	func initWithBinaryInteger__valueIsUInt8_positionIsValid__correctBitValueReturned() async throws {
		let value: UInt8 = 0b01010110

		#expect(Bit(value, position: 7) == .zero)
		#expect(Bit(value, position: 6) == .one)
		#expect(Bit(value, position: 5) == .zero)
		#expect(Bit(value, position: 4) == .one)
		#expect(Bit(value, position: 3) == .zero)
		#expect(Bit(value, position: 2) == .one)
		#expect(Bit(value, position: 1) == .one)
		#expect(Bit(value, position: 0) == .zero)
	}

	@Test
	func initWithBinaryIntegerFromLeft__valueIsUInt8_positionIsValid__correctBitValueReturned() async throws {
		let value: UInt8 = 0b01010110

		#expect(Bit(value, positionFromMostSignificant: 0) == .zero)
		#expect(Bit(value, positionFromMostSignificant: 1) == .one)
		#expect(Bit(value, positionFromMostSignificant: 2) == .zero)
		#expect(Bit(value, positionFromMostSignificant: 3) == .one)
		#expect(Bit(value, positionFromMostSignificant: 4) == .zero)
		#expect(Bit(value, positionFromMostSignificant: 5) == .one)
		#expect(Bit(value, positionFromMostSignificant: 6) == .one)
		#expect(Bit(value, positionFromMostSignificant: 7) == .zero)
	}
}
