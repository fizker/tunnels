import Testing
import Binary

struct ConversionsTests {
	@Test
	func asUInt8__inputIsUInt8__returnsExpected() {
		#expect((0xde as UInt8).asUInt8 == [0xde])
	}

	@Test
	func asUInt16__inputIsUInt8__returnsExpected() {
		#expect((0xdead as UInt16).asUInt8 == [0xde, 0xad])
	}

	@Test
	func asUInt32__inputIsUInt8__returnsExpected() {
		#expect((0xdeadbeef as UInt32).asUInt8 == [0xde, 0xad, 0xbe, 0xef])
	}

	@Test
	func asUInt64__inputIsUInt8__returnsExpected() {
		#expect((0xdeadbeef_8badf00d as UInt64).asUInt8 == [0xde, 0xad, 0xbe, 0xef, 0x8b, 0xad, 0xf0, 0x0d])
	}
}
