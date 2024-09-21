import Testing
import Binary
import Foundation

struct BitIteratorTests {
	@Test
	func next__backedByArraySlice__returnsExpectedBits() async throws {
		let value: [UInt8] = [0b00101100, 0b11111100, 0b00110100, 0b00011110]
		let slice = value[1...2]

		#expect([0b11111100, 0b00110100] == slice)
		#expect(slice.startIndex == value.startIndex + 1)
		#expect(slice.endIndex == value.endIndex - 1)

		var iterator = BitIterator(slice)

		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)

		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)

		#expect(iterator.next() == nil)
	}

	@Test
	func next__backedByUInt8__returnsExpectedBits() async throws {
		let value: UInt8 = 0b00101100
		var iterator = BitIterator(value)

		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == nil)
	}

	@Test
	func next__backedByTwoUInt8__returnsExpectedBits() async throws {
		let firstValue: UInt8 = 0b00101100
		let secondValue: UInt8 = 0b01111100
		var iterator = BitIterator([ firstValue, secondValue ])

		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)

		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .one)
		#expect(iterator.next() == .zero)
		#expect(iterator.next() == .zero)

		#expect(iterator.next() == nil)
	}

	@Test
	func nextX__backedByUInt8__returnsExpectedValues() async throws {
		let value: UInt8 = 0b00101100
		var iterator = BitIterator(value)

		#expect(iterator.next(2) == 0b00)
		#expect(iterator.next(2) == 0b10)
		#expect(iterator.next(2) == 0b11)
		#expect(iterator.next(2) == 0b00)
		#expect(iterator.next(2) == nil)

		iterator = BitIterator(value)

		#expect(iterator.next(3) == 0b001)
		#expect(iterator.next(3) == 0b011)
		// This overflows, which kills the rest of the values
		#expect(iterator.next(3) == nil)
		#expect(iterator.next() == nil)

		iterator = BitIterator(value)

		#expect(iterator.next() == .zero)
		#expect(iterator.next(3) == 0b010)
		#expect(iterator.next(3) == 0b110)
		// This overflows, which kills the rest of the values
		#expect(iterator.next(3) == nil)
		#expect(iterator.next() == nil)
	}

	@Test
	func next8__backedByUInt32__returnsExpectedValues() async throws {
		let value: UInt32 = 0b00101100_01111100_00110100_00011110

		var iterator = BitIterator(value)
		#expect(iterator.next8() == 0b00101100)
		#expect(iterator.next8() == 0b01111100)
		#expect(iterator.next8() == 0b00110100)
		#expect(iterator.next8() == 0b00011110)
		#expect(iterator.next8() == nil)

		iterator = BitIterator(value)
		#expect(iterator.next() == .zero)
		#expect(iterator.next8() == 0b01011000)
		#expect(iterator.next8() == 0b11111000)
		#expect(iterator.next8() == 0b01101000)
		#expect(iterator.next8() == nil)
	}

	@Test
	func next16__backedByUInt32__returnsExpectedValues() async throws {
		let value: UInt32 = 0b00101100_01111100_00110100_00011110

		var iterator = BitIterator(value)
		#expect(iterator.next16() == 0b00101100_01111100)
		#expect(iterator.next16() == 0b00110100_00011110)
		#expect(iterator.next16() == nil)

		iterator = BitIterator(value)
		#expect(iterator.next() == .zero)
		#expect(iterator.next16() == 0b01011000_11111000)
		#expect(iterator.next16() == nil)
	}

	@Test
	func dataWithBytes__inputContainsSufficientBytes__dataIsReturned() throws {
		let input: [UInt32] = [
			0x862a_8180, 0x0001_f201, 0xdead_beef, 0x0667_6f6f,
		]
		var iterator = BitIterator(input)

		let expected = Data([0x2a, 0x81, 0x80, 0x00, 0x01])

		_ = iterator.next8()

		let actual = iterator.data(bytes: 5)

		#expect(actual == expected)
		#expect(iterator.next8() == 0xf2)
	}

	@Test
	func dataWithBytes__inputContainsInsufficientBytes__nilIsReturned_iteratorIsLeftEmpty() throws {
		let input: [UInt8] = [
			0x86,
		]
		var iterator = BitIterator(input)

		_ = iterator.next()

		let actual = iterator.data(bytes: 1)

		#expect(actual == nil)
		#expect(iterator.next() == nil)
	}

	@Test
	func data__iteratorIsFresh__allBytesAreReturned_iteratorIsLeftEmpty() async throws {
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

		#expect(expected == actual)
		#expect(iterator.next() == nil)
	}

	@Test
	func data__partialByteRead__allFullBytesAreReturned_iteratorIsLeftEmpty() async throws {
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

		#expect(expected == actual)
		#expect(iterator.next() == nil)
	}

	@Test
	func bitIndex__skippingAround_backedByArraySlice__indexUpdatedCorrectly_indexIsNormalizedForArraySlice() async throws {
		let value: [UInt8] = [0b0010_1100, 0b1111_1100, 0b0011_0100, 0b0001_1110]
		let slice = value[1...2]

		#expect([0b1111_1100, 0b0011_0100] == slice)
		#expect(slice.startIndex == value.startIndex + 1)
		#expect(slice.endIndex == value.endIndex - 1)

		var iterator = BitIterator(slice)

		#expect(iterator.byteIndex == 0)
		#expect(iterator.bitIndex == 0)
		#expect(iterator.next8() == 0b1111_1100)
		#expect(iterator.byteIndex == 1)
		#expect(iterator.bitIndex == 8)

		iterator.bitIndex = 2
		#expect(iterator.bitIndex == 2)
		#expect(iterator.byteIndex == 1)
		#expect(iterator.next8() == 0b11_1100_00)
		#expect(iterator.byteIndex == 2)
		#expect(iterator.bitIndex == 10)
	}

	@Test
	func bitIndex__skippingAround_backedByMultipleUInt16__indexUpdatedCorrectly() throws {
		let input: [UInt16] = [
			// 0xdead
			0b1101_1110_1010_1101,
			// 0xbeef
			0b1011_1110_1110_1111,
		]

		var iterator = BitIterator(input)

		#expect(iterator.bitIndex == 0)
		#expect(iterator.next8() == 0b1101_1110)
		#expect(iterator.byteIndex == 1)
		#expect(iterator.bitIndex == 8)

		iterator.bitIndex = 2
		#expect(iterator.byteIndex == 1)
		#expect(iterator.next8() == 0b01_1110_10)
		#expect(iterator.byteIndex == 2)
		#expect(iterator.bitIndex == 10)

		iterator.bitIndex = 21
		#expect(iterator.byteIndex == 3)
		#expect(iterator.next(5) == 0b110_11)
		#expect(iterator.byteIndex == 4)
		#expect(iterator.bitIndex == 26)

		iterator.bitIndex = 1
		#expect(iterator.byteIndex == 1)
		#expect(iterator.next8() == 0b101_1110_1)
		#expect(iterator.byteIndex == 2)
		#expect(iterator.bitIndex == 9)
	}

	@Test
	func byteIndex__skippingAround_backedByMultipleUInt16__indexUpdatedCorrectly() throws {
		let input: [UInt16] = [ 0xdead, 0xbeef ]

		var iterator = BitIterator(input)

		#expect(iterator.byteIndex == 0)
		#expect(iterator.next8() == 0xde)
		#expect(iterator.byteIndex == 1)
		#expect(iterator.bitIndex == 8)

		iterator.byteIndex = 2
		#expect(iterator.next8() == 0xbe)
		#expect(iterator.byteIndex == 3)
		#expect(iterator.bitIndex == 24)

		iterator.byteIndex = 1
		#expect(iterator.next8() == 0xad)
		#expect(iterator.byteIndex == 2)
		#expect(iterator.bitIndex == 16)
		#expect(iterator.next8() == 0xbe)
		#expect(iterator.next8() == 0xef)
	}

	/// Note: This code comes from the DocC comment for ``BitIterator/byteIndex``.
	@Test
	func byteIndex__settingIndexFrom4BitsToNextByte__indexUpdatedCorrectly() throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)
		_ = iterator.next(4)
		#expect(4 == iterator.bitIndex)
		#expect(1 == iterator.byteIndex)

		// we are now in effect skipping the remaining 4 bits of the first byte
		iterator.byteIndex = iterator.byteIndex
		#expect(8 == iterator.bitIndex)
		#expect(1 == iterator.byteIndex)
	}

	@Test
	func remainingBits__singleUInt32_variousStatesOfIteration__returnsRemainingBits() async throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)

		#expect(iterator.remainingBits == 32)

		_ = iterator.next()

		#expect(iterator.remainingBits == 31)

		_ = iterator.next16()

		#expect(iterator.remainingBits == 15)

		iterator.bitIndex = 26

		#expect(iterator.remainingBits == 6)

		_ = iterator.next(4)

		#expect(iterator.remainingBits == 2)

		_ = iterator.next(4)

		#expect(iterator.remainingBits == 0)
	}

	@Test
	func remainingBits__multipleUInt32_variousStatesOfIteration__returnsRemainingBits() async throws {
		var iterator = BitIterator([0xdeadbeef, 0xdeadbeef, 0xdeadbeef] as [UInt32])

		#expect(iterator.remainingBits == 96)

		_ = iterator.next()

		#expect(iterator.remainingBits == 95)

		_ = iterator.next16()

		#expect(iterator.remainingBits == 79)

		iterator.bitIndex = 26

		#expect(iterator.remainingBits == 70)

		_ = iterator.next(4)

		#expect(iterator.remainingBits == 66)

		iterator.bitIndex = 90

		#expect(iterator.remainingBits == 6)

		_ = iterator.next(4)

		#expect(iterator.remainingBits == 2)

		_ = iterator.next(4)

		#expect(iterator.remainingBits == 0)
	}

	@Test
	func remainingBytes__variousStatesOfIteration__returnsRemainingBytes() async throws {
		var iterator = BitIterator(0xdeadbeef as UInt32)

		#expect(iterator.remainingBytes == 4)

		_ = iterator.next8()

		#expect(iterator.remainingBytes == 3)

		_ = iterator.next()

		#expect(iterator.remainingBytes == 2, "It should only count full bytes")

		iterator.bitIndex = 24

		#expect(iterator.remainingBytes == 1)

		_ = iterator.next16()

		#expect(iterator.remainingBytes == 0)
	}
}
