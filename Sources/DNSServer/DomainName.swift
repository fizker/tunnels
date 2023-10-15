import Binary
import Foundation

struct DomainName: Equatable {
	var components: [String]

	var value: String {
		components.joined(separator: ".")
	}

	init(components: [String]) {
		self.components = components
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
