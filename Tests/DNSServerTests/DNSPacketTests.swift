import XCTest
import Binary
@testable import DNSServer

final class DNSPacketTests: XCTestCase {
	func test__initWithIterator__validRequest__parsesAsExpected() throws {
		let input: [UInt32] = [
			0x862a_0120, 0x0001_0000, 0x0000_0000, 0x0667_6f6f,
			0x676c_6503, 0x636f_6d00, 0x0001_0001,
		]

		let expected = DNSPacket(
			header: .init(
				id: 0x862a,
				kind: .query,
				opcode: .query,
				isAuthoritativeAnswer: false,
				isTruncated: false,
				isRecursionDesired: true,
				isRecursionAvailable: false,
				z: 2,
				responseCode: nil,
				questionCount: 1,
				answerCount: 0,
				authorityCount: 0,
				additionalCount: 0
			),
			questions: [
				.init(
					name: .init(components: ["google", "com"]),
					type: .hostAddress,
					class: .internet
				),
			],
			answers: [
			]
		)

		var iterator = BitIterator(input)
		let actual = try DNSPacket(iterator: &iterator)

		XCTAssertEqual(actual, expected)
	}

	func test__initWithIterator__validResponse__parsesAsExpected() throws {
		let input: [UInt32] = [
			0x862a_8180, 0x0001_0001, 0x0000_0000, 0x0667_6f6f,
			0x676c_6503, 0x636f_6d00, 0x0001_0001, 0xc00c_0001,
			0x0001_0000, 0x0125_0004, 0xd83a_d38e,
		]
		let expected = DNSPacket(
			header: .init(
				id: 0x862a,
				kind: .response,
				opcode: .query,
				isAuthoritativeAnswer: false,
				isTruncated: false,
				isRecursionDesired: true,
				isRecursionAvailable: true,
				z: 0,
				responseCode: nil,
				questionCount: 1,
				answerCount: 1,
				authorityCount: 0,
				additionalCount: 0
			),
			questions: [
				.init(
					name: .init(components: ["google", "com"]),
					type: .hostAddress,
					class: .internet
				),
			],
			answers: [
				.init(
					name: .init(components: ["google", "com"]),
					type: .hostAddress,
					class: .internet,
					timeToLive: 0x125,
					length: 4,
					data: .ipV4(0xd8, 0x3a, 0xd3, 0x8e)
				)
			]
		)

		var iterator = BitIterator(input)
		let actual = try DNSPacket(iterator: &iterator)

		XCTAssertEqual(actual, expected)
	}
}
