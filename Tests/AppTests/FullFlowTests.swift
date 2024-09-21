import AsyncHTTPClient
import Common
import Crypto
import NIOCore
import Vapor
import XCTest

/// # Note
///
/// These tests require the different components to run externally when starting the tests
/// - `TunnelServer` must run on `localhost:8110`.
/// - `DebugServer` must run.
/// - `TunnelClient` must run against `TunnelServer` with `test.fizkerinc.dk` pointing to `DebugServer`.
final class FullFlowTests: XCTestCase {
	let timeout: TimeAmount = .seconds(10)

	func test__DebugServer__catchAll__returnsExpectedBody() async throws {
		let client = HTTPClient()
		defer { Task {
			try? await client.shutdown()
		} }

		let request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/foo")
		let response = try await client.execute(request, timeout: timeout)

		XCTAssertEqual(response.status, .ok)
		let data = try await readBody(from: response)
		let value = data.flatMap { String(data: $0, encoding: .utf8) }
		XCTAssertEqual(value, "Hello World at /foo")
	}

	func test__DebugServer__redirect__redirectResponseIsReceivedCorrectly() async throws {
		let client = HTTPClient(configuration: .init(redirectConfiguration: .disallow))
		defer { Task {
			try? await client.shutdown()
		} }

		let request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/redirect?location=example.com")
		let response = try await client.execute(request, timeout: timeout)

		XCTAssertEqual(response.status, .temporaryRedirect)
		XCTAssertEqual(response.headers["location"], ["example.com"])

		let data = try await readBody(from: response)
		XCTAssertNil(data)
	}

	func test__DebugServer__bigFile__returnsExpectedBody() async throws {
		let client = HTTPClient()
		defer { Task {
			try? await client.shutdown()
		} }

		let size = 1_000_000

		let request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/big-file?size=\(size)")
		let response = try await client.execute(request, timeout: timeout)

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

	func test__DebugServer__upload_smallFile__returnsExpectedBody() async throws {
		let data = await AsyncStream(generateDataStreamOfSize: 10)
			.reduce(into: Data()) { $0.append($1) }
		let digest = SHA256.hash(data: data)

		var request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/upload?digest=\(digest.hex)")
		request.method = .POST
		request.body = .bytes(data, length: .unknown)

		let client = HTTPClient()
		defer { Task {
			try? await client.shutdown()
		} }

		let response = try await client.execute(request, timeout: timeout)
		XCTAssertEqual(response.status, .ok)

		let body = try await readBody(from: response)
		let value = body.flatMap { String(data: $0, encoding: .utf8) }
		XCTAssertEqual(value, "Content received correctly")
	}

	func test__DebugServer__upload_bigFile__returnsExpectedBody() async throws {
		let data = await AsyncStream(generateDataStreamOfSize: 1_000_000)
			.reduce(into: Data()) { $0.append($1) }
		let digest = SHA256.hash(data: data)

		var request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/upload?digest=\(digest.hex)")
		request.method = .POST
		request.body = .bytes(data, length: .unknown)

		let client = HTTPClient()
		defer { Task {
			try? await client.shutdown()
		} }

		let response = try await client.execute(request, timeout: timeout)
		XCTAssertEqual(response.status, .ok)

		let body = try await readBody(from: response)
		let value = body.flatMap { String(data: $0, encoding: .utf8) }
		XCTAssertEqual(value, "Content received correctly")
	}

	func tunnelServerRequest(host: String, path: String) -> HTTPClientRequest {
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
