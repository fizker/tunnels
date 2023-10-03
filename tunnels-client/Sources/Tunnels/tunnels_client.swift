import AsyncHTTPClient
import Foundation

public func hello() async throws -> String {
	let client = HTTPClient()
	defer { _ = client.shutdown() }
	let response = try await client.get(url: "http://localhost:8110/hello")
	let body = try await response.body.collect(upTo: 1024 * 1024)
	return String(data: Data(buffer: body), encoding: .utf8) ?? ""
}

extension HTTPClient {
	func get(url: String) async throws -> HTTPClientResponse {
		let request = HTTPClientRequest(url: url)
		return try await execute(request, timeout: .seconds(30))
	}
}
