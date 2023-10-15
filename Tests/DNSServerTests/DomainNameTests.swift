import XCTest
import Binary
import Foundation
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

	func test__initWithIterator__contentIsCompressed__dataIsParsedCorrectly() throws {
		let expected = DomainName(components: [
			// 0x67 0x6f 0x6f 0x67 0x6c 0x65
			"google",
			// 0x63 0x6f 0x6d
			"com"
		])

		let input: [UInt32] = [
			0x862a_8180, 0x0001_0001, 0x0000_0000,
			// google starts 12 bytes in
			0x0667_6f6f,
			0x676c_6503, 0x636f_6d00,
			// com ends
			0x0001_0001,
			// compressed value starts after 4 bytes, is compressed in two bytes
			0xc00c_0001,
			0x0001_0000, 0x0125_0004, 0xd83a_d38e,
		]
		var iterator = BitIterator(input)

		// Shifting iterator forward until the first name starts
		_ = iterator.data(bytes: 12)

		XCTAssertEqual(expected, try DomainName(iterator: &iterator))

		// Shift iterator again until the next name start, which is compressed
		_ = iterator.data(bytes: 4)

		XCTAssertEqual(expected, try DomainName(iterator: &iterator))

		XCTAssertNotNil(iterator.data(bytes: 14))
		XCTAssertNil(iterator.next())
	}

	/// The following example is taken from https://www.rfc-editor.org/rfc/rfc1035.html#section-4.1.4
	///
	/// | Offset	| Value				|
	/// | ----- 	| -------				|
	/// | 20		|	Byte(1)	ASCII(F)	|
	/// | 22		|	Byte(3)	ASCII(I)	|
	/// | 24		|	ASCII(S)	ASCII(I)	|
	/// | 26		|	Byte(4)	ASCII(A)	|
	/// | 28		|	ASCII(R)	ASCII(P)	|
	/// | 30		|	ASCII(A)	Byte(0)	|
	///	| 32 - 39	|	not specified for test	|
	/// | 40		|	Byte(3)	ASCII(F)	|
	/// | 42		|	ASCII(O)	ASCII(O)	|
	/// | 44		| Bit(1) Bit(1)	Int14(20)	|
	/// | 46 - 63	|	not specified for test	|
	/// | 64 		| Bit(1) Bit(1)	Int14(26)	|
	/// | 66 - 91	|	not specified for test	|
	/// | 92 		|	Byte(0)			|
	func test__initWithIterator__multipleLabelsGiven__parsesAllAsExpected() throws {
		typealias A = [UInt8]
		let input: A = A(repeating: 0xFF, count: 20) + [
			1,			/*F*/70,
			3,			/*I*/73,
			/*S*/83,	/*I*/73,
			4,			/*A*/65,
			/*R*/82,	/*P*/80,
			/*A*/65,	0,
		] as A + A(repeating: 0xFF, count: 8) + [
			3,			/*F*/70,
			/*O*/79,	/*O*/79,
			0b1100_0000,20,
		] as A + A(repeating: 0xFF, count: 18) + [
			0b1100_0000,26,
		] as A + A(repeating: 0xFF, count: 26) + [
			0
		] as A

		XCTAssertEqual(input.count, 93)

		var iterator = BitIterator(input)
		_ = iterator.byteIndex = 20

		XCTAssertEqual(try DomainName(iterator: &iterator), DomainName(components: ["F", "ISI", "ARPA"]))

		iterator.byteIndex = 40
		XCTAssertEqual(try DomainName(iterator: &iterator), DomainName(components: ["FOO", "F", "ISI", "ARPA"]))

		iterator.byteIndex = 64
		XCTAssertEqual(try DomainName(iterator: &iterator), DomainName(components: ["ARPA"]))
	}

	func test__asData__googleCom__encodesAsExpected() throws {
		let domainName = DomainName(components: ["google", "com"])
		let expected = Data([ 0x06, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x03, 0x63, 0x6f, 0x6d, 0x00 ])

		let actual = domainName.asData()

		XCTAssertEqual(expected, actual)
	}
}
