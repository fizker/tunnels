import Binary
import Foundation

enum ParseError: Error {
	/// The bytes did not add up to the expected count.
	case endOfStream
	/// The data extracted could not be parsed as ASCII.
	case notASCII(Data)
}

struct DomainName {
	var components: [String]

	var value: String {
		components.joined(separator: ".")
	}

	init(iterator: inout BitIterator) throws {
		try self.init(iterator: { iterator.next8() })
	}

	init(iterator: () -> UInt8?) throws {
		components = []

		while let length = iterator() {
			// This is the RFC-given way that this should end
			guard length != 0
			else { return }

			var data = Data()
			for _ in 0..<length {
				guard let value = iterator()
				else { throw ParseError.endOfStream }
				data.append(value)
			}
			guard let word = String(data: data, encoding: .ascii)
			else { throw ParseError.notASCII(data) }

			components.append(word)
		}

		throw ParseError.endOfStream
	}
}
