import XCTest
@testable import Models

final class HTTPHeadersTests: XCTestCase {
	func test__add__nameHasSameCasing__allValuesAreStored() async throws {
		var headers = HTTPHeaders()
		headers.add(value: "foo", for: "test")
		headers.add(value: "bar", for: "test")

		XCTAssertEqual(["foo", "bar"], headers.headers(named: "test"))
	}

	func test__add__nameHasDifferentCasing__allValuesAreStored() async throws {
		var headers = HTTPHeaders()
		headers.add(value: "foo", for: "test")
		headers.add(value: "bar", for: "Test")

		XCTAssertEqual(["foo", "bar"], headers.headers(named: "test"))
	}

	func test__firstHeaderNamed__queryHaveSameCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": ["bar", "baz"]])

		XCTAssertEqual("bar", headers.firstHeader(named: "foo"))
	}

	func test__firstHeaderNamed__queryHaveDifferentCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": ["bar", "baz"]])

		XCTAssertEqual("bar", headers.firstHeader(named: "Foo"))
	}

	func test__headersNamed__queryHaveSameCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": "bar"])

		XCTAssertEqual(["bar"], headers.headers(named: "foo"))
	}

	func test__headersNamed__queryHaveDifferentCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": "bar"])

		XCTAssertEqual(["bar"], headers.headers(named: "Foo"))
	}

	func test__map__multipleHeaders__allHeadersAreReported() async throws {
		let expected = [ "foo": ["bar", "baz"], "111": ["222"]]
		let headers = HTTPHeaders(expected)

		let actual: [String:[String]]

		actual = .init(uniqueKeysWithValues: headers.map { ($0, $1) })

		XCTAssertEqual(expected, actual)
	}

	func test__removeValueForName__valueMatchesExactly_nameMatchesExactly_multipleValuesWithName__valueIsRemoved() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.remove(value: "bar", for: "foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, ["baz"])
	}

	func test__removeValueForName__valueMatchesExactly_nameHasDifferentCasing_multipleValuesWithName__valueIsRemoved() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.remove(value: "bar", for: "Foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, ["baz"])
	}

	func test__removeValueForName__valueHasDifferentCasing_nameMatchesExactly_multipleValuesWithName__valueIsKept() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.remove(value: "Bar", for: "foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, ["bar", "baz"])
	}

	func test__removeValueForName__valueHasDifferentCasing_nameHasDifferentCasing_multipleValuesWithName__valueIsKept() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.remove(value: "Bar", for: "Foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, ["bar", "baz"])
	}

	func test__removeAll__nameMatchesCase__allValuesAreRemoved() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.removeAll(named: "foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, [])
	}

	func test__removeAll__nameHasDifferentCase__allValuesAreRemoved() async throws {
		var headers = HTTPHeaders([ "foo": ["bar", "baz"], "111": ["222"]])

		headers.removeAll(named: "Foo")

		let values = headers.headers(named: "foo")
		XCTAssertEqual(values, [])
	}

	func test__set__nameHasSameCasing__existingValueIsOverwritten() async throws {
		var headers = HTTPHeaders(["foo": "bar"])
		headers.set(value: "baz", for: "foo")

		XCTAssertEqual(headers.headers(named: "foo"), ["baz"])
	}

	func test__set__nameHasDifferentCasing__existingValueIsOverwritten() async throws {
		var headers = HTTPHeaders(["foo": "bar"])
		headers.set(value: "baz", for: "Foo")

		XCTAssertEqual(headers.headers(named: "foo"), ["baz"])
	}

	func test__encode__multipleHeadersAndValues__encodesAsExpected() async throws {
		let headers = HTTPHeaders(["foo": ["bar", "baz"], "111": ["222"]])

		let expected = """
		{
		  "values" : {
		    "111" : [
		      "222"
		    ],
		    "foo" : [
		      "bar",
		      "baz"
		    ]
		  }
		}
		"""

		let actual = try encode(headers)
		XCTAssertEqual(actual, expected)
	}

	func test__decode__multipleHeadersAndValues__decodesAsExpected() async throws {
		let expected = HTTPHeaders(["foo": ["bar", "baz"], "111": ["222"]])

		let json = """
		{
		  "values" : {
		    "foo" : [
		      "bar",
		      "baz"
		    ],
		    "111" : [
		      "222"
		    ]
		  }
		}
		"""

		let actual = try decode(HTTPHeaders.self, from: json)
		XCTAssertEqual(actual.values, expected.values)
	}
}

func encode(_ value: some Encodable) throws -> String {
	let encoder = JSONEncoder()
	encoder.outputFormatting = [ .prettyPrinted, .sortedKeys ]

	let data = try encoder.encode(value)
	let json = String(data: data, encoding: .utf8)!
	return json
}

func decode<T: Decodable>(_ type: T.Type = T.self, from value: String) throws -> T {
	let decoder = JSONDecoder()

	let data = value.data(using: .utf8)!

	return try decoder.decode(type, from: data)
}
