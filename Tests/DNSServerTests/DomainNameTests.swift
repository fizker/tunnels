import XCTest
import Binary
@testable import DNSServer

final class DomainNameTests: XCTestCase {
	func test__initWithIterator__validDomainName__dataIsParsedCorrectly() throws {
		let input: [UInt32] = [ 0x0667_6f6f, 0x676c_6503, 0x636f_6d00 ]
		var iterator = BitIterator(input)

		let domainName = try DomainName(iterator: &iterator)

		XCTAssertEqual(domainName.components, ["google", "com"])
		XCTAssertEqual(domainName.value, "google.com")

		XCTAssertNil(iterator.next())
	}
}
