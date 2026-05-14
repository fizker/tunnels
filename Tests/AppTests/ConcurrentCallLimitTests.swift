import AsyncHTTPClient
import Foundation
import NIOHTTP1
import Testing

@Suite(.serialized)
struct ConcurrentCallLimitTests {
	static let tunnelServerPort = Int.random(in: 37_000..<40_000)
	var tunnelServerPort: Int { Self.tunnelServerPort }
	static let debugServerPort = Int.random(in: 40_000..<43_000)
	var debugServerPort: Int { Self.debugServerPort }

	@Test(StartDebugServer(port: debugServerPort), arguments: [
		(1, 20, true),
	])
	func debugServer__multipleCallsStartedInParallel__responseExpectedToLandReasonablyClose(delay: Int, concurrent: Int, raiseHTTP1Limit: Bool) async throws {
		let request = HTTPClientRequest(url: "http://localhost:\(debugServerPort)/delayed?delay=\(delay)")

		var config = HTTPClient.Configuration()
		if raiseHTTP1Limit {
			config.connectionPool.concurrentHTTP1ConnectionsPerHostSoftLimit = concurrent
		}
		let client = HTTPClient(configuration: config)
		defer {
			Task { try await client.shutdown() }
		}

		let results = try await exec(request, on: client, concurrent: concurrent)

		var count = 1
		for (response, runTime) in results {
			#expect(response.status == .ok, "request: \(count)")
			#expect(runTime.isApproximatelyEqual(to: TimeInterval(delay), absoluteTolerance: 0.3), "request: \(count)")
			count += 1
		}
	}

	@Test(DebugServerTunnel(tunnelServerPort: tunnelServerPort, debugServerPort: debugServerPort, debugServerHostName: "test.fizkerinc.dk"), arguments: [
		(1, 20, true),
	])
	func tunnel__multipleCallsStartedInParallel__responseExpectedToLandReasonablyClose(delay: Int, concurrent: Int, raiseHTTP1Limit: Bool) async throws {
		let request = tunnelServerRequest(host: "test.fizkerinc.dk", path: "/delayed?delay=\(delay)")

		var config = HTTPClient.Configuration()
		if raiseHTTP1Limit {
			config.connectionPool.concurrentHTTP1ConnectionsPerHostSoftLimit = concurrent
		}
		let client = HTTPClient(configuration: config)
		defer {
			Task { try await client.shutdown() }
		}

		let results = try await exec(request, on: client, concurrent: concurrent)

		var count = 1
		for (response, runTime) in results {
			#expect(response.status == .ok, "request: \(count)")
			#expect(runTime.isApproximatelyEqual(to: TimeInterval(delay), absoluteTolerance: 0.3), "request: \(count)")
			count += 1
		}
	}

	func tunnelServerRequest(host: String, path: String) -> HTTPClientRequest {
		var request = HTTPClientRequest(url: "http://localhost:\(tunnelServerPort)\(path)")
		request.method = .GET
		request.headers.replaceOrAdd(name: "host", value: host)
		return request
	}

	private func exec(_ request: HTTPClientRequest, on client: HTTPClient, concurrent: Int) async throws -> [(HTTPClientResponse, TimeInterval)] {
		let startTime = Date.now

		let results = try await withThrowingTaskGroup { group in
			for _ in 0..<concurrent {
				group.addTask {
					return (
						try await client.execute(request, timeout: .seconds(10)),
						startTime.distance(to: .now),
					)
				}
			}

			var responses: [(HTTPClientResponse, TimeInterval)] = []
			for try await response in group {
				responses.append(response)
			}

			return responses
		}

		return results
	}
}
