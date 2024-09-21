import Testing
import Binary

struct BitSequence {
	@Test
	func appendWithBits__fourBitsRequested_inputTypeIsUInt__theExpectBitsAreAdded() throws {
		var sequence = [Bit]()
		sequence.append(0xbad as UInt, bits: 4)

		#expect(sequence == [.one, .one, .zero, .one])
	}
}
