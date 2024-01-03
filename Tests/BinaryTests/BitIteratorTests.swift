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

	func test__dataWithBytes__inputContainsSufficientBytes__dataIsReturned() throws {
		let input: [UInt32] = [
			0x862a_8180, 0x0001_f201, 0xdead_beef, 0x0667_6f6f,
		]
		var iterator = BitIterator(input)

		let expected = Data([0x2a, 0x81, 0x80, 0x00, 0x01])

		_ = iterator.next8()

		let actual = iterator.data(bytes: 5)

		XCTAssertEqual(actual, expected)
		XCTAssertEqual(iterator.next8(), 0xf2)
	}

	func test__dataWithBytes__inputContainsInsufficientBytes__nilIsReturned_iteratorIsLeftEmpty() throws {
		let input: [UInt8] = [
			0x86,
		]
		var iterator = BitIterator(input)

		_ = iterator.next()

		let actual = iterator.data(bytes: 1)

		XCTAssertNil(actual)
		XCTAssertNil(iterator.next())
	}

	func test__data__iteratorIsFresh__allBytesAreReturned_iteratorIsLeftEmpty() async throws {
		let input: [UInt32] = [
			0x862a_8180, 0x0001_f201, 0xdead_beef, 0x0667_6f6f,
		]

		var iterator = BitIterator(input)

		let expected = Data([
			0x86, 0x2a, 0x81, 0x80,
			0x00, 0x01, 0xf2, 0x01,
			0xde, 0xad, 0xbe, 0xef,
			0x06, 0x67, 0x6f, 0x6f,
		])
		let actual = iterator.data()

		XCTAssertEqual(expected, actual)
		XCTAssertNil(iterator.next())
	}

	func test__data__partialByteRead__allFullBytesAreReturned_iteratorIsLeftEmpty() async throws {
		let input: [UInt32] = [
			0b00101100_01111100_00110100_00011110,
		]

		var iterator = BitIterator(input)

		_ = iterator.next()

		let expected = Data([
			0b01011000,
			0b11111000,
			0b01101000,
		])
		let actual = iterator.data()

		XCTAssertEqual(expected, actual)
		XCTAssertNil(iterator.next())
	}

	func test__bitIndex__skippingAround_backedByMultipleUInt16__indexUpdatedCorrectly() throws {
		let input: [UInt16] = [
			// 0xdead
			0b1101_1110_1010_1101,
			// 0xbeef
			0b1011_1110_1110_1111,
		]

		var iterator = BitIterator(input)

		XCTAssertEqual(iterator.bitIndex, 0)
		XCTAssertEqual(iterator.next8(), 0b1101_1110)
		XCTAssertEqual(iterator.byteIndex, 1)
		XCTAssertEqual(iterator.bitIndex, 8)

		iterator.bitIndex = 2
		XCTAssertEqual(iterator.byteIndex, 1)
		XCTAssertEqual(iterator.next8(), 0b01_1110_10)
		XCTAssertEqual(iterator.byteIndex, 2)
		XCTAssertEqual(iterator.bitIndex, 10)

		iterator.bitIndex = 21
		XCTAssertEqual(iterator.byteIndex, 3)
		XCTAssertEqual(iterator.next(5), 0b110_11)
		XCTAssertEqual(iterator.byteIndex, 4)
		XCTAssertEqual(iterator.bitIndex, 26)

		iterator.bitIndex = 1
		XCTAssertEqual(iterator.byteIndex, 1)
		XCTAssertEqual(iterator.next8(), 0b101_1110_1)
		XCTAssertEqual(iterator.byteIndex, 2)
		XCTAssertEqual(iterator.bitIndex, 9)
	}

	func test__byteIndex__skippingAround_backedByMultipleUInt16__indexUpdatedCorrectly() throws {
		let input: [UInt16] = [ 0xdead, 0xbeef ]

		var iterator = BitIterator(input)

		XCTAssertEqual(iterator.byteIndex, 0)
		XCTAssertEqual(iterator.next8(), 0xde)
		XCTAssertEqual(iterator.byteIndex, 1)
		XCTAssertEqual(iterator.bitIndex, 8)

		iterator.byteIndex = 2
		XCTAssertEqual(iterator.next8(), 0xbe)
		XCTAssertEqual(iterator.byteIndex, 3)
		XCTAssertEqual(iterator.bitIndex, 24)

		iterator.byteIndex = 1
		XCTAssertEqual(iterator.next8(), 0xad)
		XCTAssertEqual(iterator.byteIndex, 2)
		XCTAssertEqual(iterator.bitIndex, 16)
		XCTAssertEqual(iterator.next8(), 0xbe)
		XCTAssertEqual(iterator.next8(), 0xef)
	}

	/// Note: This code comes from the DocC comment for ``BitIterator/byteIndex``.
	func test__byteIndex__settingIndexFrom4BitsToNextByte__indexUpdatedCorrectly() throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)
		_ = iterator.next(4)
		XCTAssertEqual(4, iterator.bitIndex)
		XCTAssertEqual(1, iterator.byteIndex)

		// we are now in effect skipping the remaining 4 bits of the first byte
		iterator.byteIndex = iterator.byteIndex
		XCTAssertEqual(8, iterator.bitIndex)
		XCTAssertEqual(1, iterator.byteIndex)
	}

	func test__remainingBits__singleUInt32_variousStatesOfIteration__returnsRemainingBits() async throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)

		XCTAssertEqual(iterator.remainingBits, 32)

		_ = iterator.next()

		XCTAssertEqual(iterator.remainingBits, 31)

		_ = iterator.next16()

		XCTAssertEqual(iterator.remainingBits, 15)

		iterator.bitIndex = 26

		XCTAssertEqual(iterator.remainingBits, 6)

		_ = iterator.next(4)

		XCTAssertEqual(iterator.remainingBits, 2)

		_ = iterator.next(4)

		XCTAssertEqual(iterator.remainingBits, 0)
	}

	func test__remainingBits__multipleUInt32_variousStatesOfIteration__returnsRemainingBits() async throws {
		var iterator = BitIterator([0xdeadbeef, 0xdeadbeef, 0xdeadbeef] as [UInt32])

		XCTAssertEqual(iterator.remainingBits, 96)

		_ = iterator.next()

		XCTAssertEqual(iterator.remainingBits, 95)

		_ = iterator.next16()

		XCTAssertEqual(iterator.remainingBits, 79)

		iterator.bitIndex = 26

		XCTAssertEqual(iterator.remainingBits, 70)

		_ = iterator.next(4)

		XCTAssertEqual(iterator.remainingBits, 66)

		iterator.bitIndex = 90

		XCTAssertEqual(iterator.remainingBits, 6)

		_ = iterator.next(4)

		XCTAssertEqual(iterator.remainingBits, 2)

		_ = iterator.next(4)

		XCTAssertEqual(iterator.remainingBits, 0)
	}

	func test__remainingBytes__variousStatesOfIteration__returnsRemainingBytes() async throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)

		XCTAssertEqual(iterator.remainingBytes, 4)

		_ = iterator.next8()

		XCTAssertEqual(iterator.remainingBytes, 3)

		_ = iterator.next()

		XCTAssertEqual(iterator.remainingBytes, 2, "It should only count full bytes")

		iterator.bitIndex = 24

		XCTAssertEqual(iterator.remainingBytes, 1)

		_ = iterator.next16()

		XCTAssertEqual(iterator.remainingBytes, 0)
	}
}
