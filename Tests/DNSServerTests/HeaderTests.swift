import XCTest
import Binary
@testable import DNSServer

final class HeaderTests: XCTestCase {
	func test__initWithIterator__contentIsValid__headerIs() throws {
		let input: [UInt32] = [0x862a_0120, 0x0001_0000, 0x0000_0000]
		var iterator = BitIterator(input)

		guard let header = Header(iterator: &iterator)
		else {
			XCTFail("header is nil")
			return
		}

		XCTAssertEqual(header.id, 0x862a)
		XCTAssertEqual(header.kind, .query)
		XCTAssertEqual(header.opcode, .query)
		XCTAssertFalse(header.isAuthoritativeAnswer)
		XCTAssertFalse(header.isTruncated)
		XCTAssertTrue(header.isRecursionDesired)
		XCTAssertFalse(header.isRecursionAvailable)
		XCTAssertEqual(header.z, 0b010)
		XCTAssertNil(header.responseCode)
		XCTAssertEqual(header.questionCount, 1)
		XCTAssertEqual(header.answerCount, 0)
		XCTAssertEqual(header.authorityCount, 0)
		XCTAssertEqual(header.additionalCount, 0)
		XCTAssertNil(iterator.next())
	}
}
