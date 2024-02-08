import AsyncHTTPClient
import Vapor
import Crypto
import NIOCore
import XCTest

/// # Note
///
/// These tests require the different components to run externally when starting the tests
final class FullFlowTests: XCTestCase {
	func test__DebugServer__catchAll__returnsExpectedBody() async throws {
		let client = HTTPClient()
		defer { try? client.syncShutdown() }

		let request = try tunnelServerRequest(host: "test.fizkerinc.dk", path: "/foo")
		let response = try await client.execute(request, timeout: .seconds(30))

		XCTAssertEqual(response.status, .ok)
		let data = try await readBody(from: response)
		let value = data.flatMap { String(data: $0, encoding: .utf8) }
		XCTAssertEqual(value, "Hello World at /foo")
	}

	func test__DebugServer__bigFile__returnsExpectedBody() async throws {
		let client = HTTPClient()
		defer { try? client.syncShutdown() }

		let size = 1_000_000

		let request = try tunnelServerRequest(host: "test.fizkerinc.dk", path: "/big-file?size=\(size)")
		let response = try await client.execute(request, timeout: .seconds(30))

		XCTAssertEqual(response.status, .ok)

		guard let data = try await readBody(from: response)
		else {
			XCTFail("No body available")
			return
		}
		XCTAssertEqual(data.count, size)

		let actualDigest = SHA256.hash(data: data)
		let expectedDigest = response.headers.first(name: "x-digest-value")
		XCTAssertEqual(expectedDigest, actualDigest.hex)
	}

	// TODO: Make test sending large body to server

	func tunnelServerRequest(host: String, path: String) throws -> HTTPClientRequest {
		var request = HTTPClientRequest(url: "http://localhost:8110\(path)")
		request.method = .GET
		request.headers.replaceOrAdd(name: "host", value: host)
		return request
	}

	func readBody(from response: HTTPClientResponse) async throws -> Data? {
		var iterator = response.body.makeAsyncIterator()
		var d = Data()
		while let buffer = try await iterator.next() {
			d.append(buffer)
		}

		return d.isEmpty ? nil : d
	}
}

extension Data {
	mutating func append(_ buffer: ByteBuffer) {
		var buffer = buffer
		if let data = buffer.readData(length: buffer.readableBytes) {
			append(data)
		}
	}
}
