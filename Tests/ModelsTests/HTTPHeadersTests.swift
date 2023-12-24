import XCTest
@testable import Models

final class HTTPHeadersTests: XCTestCase {
	func test__add__nameHasSameCasing__allValuesAreStored() async throws {
		var headers = HTTPHeaders()
		headers.add(value: "foo", for: "test")
		headers.add(value: "bar", for: "test")

		XCTAssertEqual(["foo", "bar"], headers.headers(named: "test"))
	}

	func test__firstHeaderNamed__queryHaveSameCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": ["bar", "baz"]])

		XCTAssertEqual("bar", headers.firstHeader(named: "foo"))
	}

	func test__headersNamed__queryHaveSameCasing__allValuesAreReturned() async throws {
		let headers = HTTPHeaders(["foo": "bar"])

		XCTAssertEqual(["bar"], headers.headers(named: "foo"))
	}

	func test__map__multipleHeaders__allHeadersAreReported() async throws {
		let expected = [ "foo": ["bar", "baz"], "111": ["222"]]
		let headers = HTTPHeaders(expected)

		let actual: [String:[String]]

		actual = .init(uniqueKeysWithValues: headers.map { ($0, $1) })

		XCTAssertEqual(expected, actual)
	}

	func test__set__nameHasSameCasing__existingValueIsOverwritten() async throws {
		var headers = HTTPHeaders(["foo": "bar"])
		headers.set(value: "baz", for: "foo")

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
