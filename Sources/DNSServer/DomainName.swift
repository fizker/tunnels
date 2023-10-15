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
		components = []

		while let header = LabelHeader(iterator: &iterator) {
			let length: UInt8
			switch header {
			case let .pointer(positionOfData):
				// name is compressed
				let iteratorPosition = iterator.bitIndex
				iterator.byteIndex = positionOfData

				let decompressedValue = try Self(iterator: &iterator)
				iterator.bitIndex = iteratorPosition
				components += decompressedValue.components

				// The label ends when a pointer is found. We can skip from here
				return
			case let .length(value):
				length = value
			}

			// This is the RFC-given way that this should end
			guard length != 0
			else { return }

			var data = Data()
			for _ in 0..<length {
				guard let value = iterator.next8()
				else { throw ParseError.endOfStream }
				data.append(value)
			}
			guard let word = String(data: data, encoding: .ascii)
			else { throw ParseError.notASCII(data) }

			components.append(word)
		}

		throw ParseError.endOfStream
	}

	func asData() -> Data {
		var data = Data()
		for component in components {
			#warning("DomainName component should be encoded in case utf8 chars are present")
			let encoded = component.data(using: .ascii)!
			data.append(UInt8(truncatingIfNeeded: encoded.count))
			data.append(encoded)
		}
		data.append(0)
		return data
	}

	enum LabelHeader {
		case length(UInt8)
		case pointer(Int)

		init?(iterator: inout BitIterator) {
			guard let signifier = iterator.next(2)
			else { return nil }

			switch signifier {
			case 0b11:
				guard let rest = iterator.next(14)
				else { return nil }
				self = .pointer(Int(rest))
			default:
				guard let rest = iterator.next(6)
				else { return nil }
				self = .length(UInt8(truncatingIfNeeded: rest))
			}
		}
	}
}
