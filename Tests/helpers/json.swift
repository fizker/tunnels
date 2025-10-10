import Common
import FzkExtensions

package func encode(_ value: some Encodable) throws -> String {
	let coder = Coder()
	let data = try coder.encode(value)
	return try String(data: data, encoding: .utf8).unwrap()
}

package func decode<T: Decodable>(_ string: String) throws -> T {
	let coder = Coder()
	let data = try string.data(using: .utf8).unwrap()
	return try coder.decode(T.self, from: data)
}

package func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
	try decode(string)
}
