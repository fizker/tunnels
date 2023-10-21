import XCTest
import Binary

final class ConversionsTests: XCTestCase {
	func test__variousNumbers__returnsExpected() throws {
		let tests: [(input: any BinaryInteger&UnsignedInteger, expected: [UInt8])] = [
			(0xde as UInt8, [0xde]),
			(0xdead as UInt16, [0xde, 0xad]),
			(0xdeadbeef as UInt32, [0xde, 0xad, 0xbe, 0xef]),
			(0xdeadbeef_8badf00d as UInt64, [0xde, 0xad, 0xbe, 0xef, 0x8b, 0xad, 0xf0, 0x0d]),
		]

		for test in tests {
			let actual = test.input.asUInt8
			XCTAssertEqual(test.expected, actual)
		}
	}
}
