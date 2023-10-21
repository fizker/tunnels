import XCTest
import Binary

final class BitSequence: XCTestCase {
	func test__appendWithBits__fourBitsRequested_inputTypeIsUInt__theExpectBitsAreAdded() throws {
		var sequence = [Bit]()
		sequence.append(0xbad as UInt, bits: 4)

		XCTAssertEqual(sequence, [.one, .one, .zero, .one])
	}
}
