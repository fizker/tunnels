import Binary
import Testing
@testable import DNSServer

struct HeaderTests {
	@Test
	func initWithIterator__contentIsValid__headerIs() throws {
		let input: [UInt32] = [0x862a_0120, 0x0001_0000, 0x0000_0000]
		var iterator = BitIterator(input)

		let header = try #require(Header(iterator: &iterator))

		#expect(header.id == 0x862a)
		#expect(header.kind == .query)
		#expect(header.opcode == .query)
		#expect(false == header.isAuthoritativeAnswer)
		#expect(false == header.isTruncated)
		#expect(true == header.isRecursionDesired)
		#expect(false == header.isRecursionAvailable)
		#expect(header.z == 0b010)
		#expect(header.responseCode == nil)
		#expect(header.questionCount == 1)
		#expect(header.answerCount == 0)
		#expect(header.authorityCount == 0)
		#expect(header.additionalCount == 0)
		#expect(iterator.next() == nil)
	}
}
