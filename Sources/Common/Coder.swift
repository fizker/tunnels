import Foundation
import FzkExtensions

package struct Coder {
	let encoder = JSONEncoder() ~ {
		$0.outputFormatting = [
			.prettyPrinted,
			.sortedKeys,
			.withoutEscapingSlashes,
		]
		$0.dateEncodingStrategy = .iso8601
		$0.dataEncodingStrategy = .base64
	}
	let decoder = JSONDecoder() ~ {
		$0.dateDecodingStrategy = .iso8601
		$0.dataDecodingStrategy = .base64
	}

	package init() {
	}

	package func encode(_ value: some Encodable) throws -> Data {
		return try encoder.encode(value)
	}

	package func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
		return try decoder.decode(T.self, from: data)
	}

	package func decode<T: Decodable>(_ data: Data) throws -> T {
		return try decoder.decode(T.self, from: data)
	}
}
