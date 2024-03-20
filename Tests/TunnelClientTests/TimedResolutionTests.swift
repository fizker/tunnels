import XCTest
@testable import TunnelClient

final class TimedResolutionTests: XCTestCase {
	func test__resolve__resolvesBeforeTimeout__resultIsResolved() async throws {
		let (stream, continuation) = AsyncStream.makeStream(of: TestResult.self)
		let timer = TimedResolution(timeout: .milliseconds(100)) { result in
			continuation.yield(.resolved(result))
		}

		Task.detached {
			do {
				try await Task.sleep(for: .milliseconds(50))
				await timer.resolve()
			} catch {
				continuation.yield(.error(error))
			}
		}

		let result = await stream.first { _ in true }

		XCTAssertEqual(result, .resolved(.resolved))
		let isResolved = await timer.isResolved
		XCTAssertTrue(isResolved)
	}

	func test__resolve__resolvesAfterTimeout__resultIsTimedOut() async throws {
		let (stream, continuation) = AsyncStream.makeStream(of: TestResult.self)
		let timer = TimedResolution(timeout: .milliseconds(100)) { result in
			continuation.yield(.resolved(result))
		}

		Task.detached {
			do {
				try await Task.sleep(for: .milliseconds(150))
				await timer.resolve()
			} catch {
				continuation.yield(.error(error))
			}
		}

		let result = await stream.first { _ in true }

		XCTAssertEqual(result, .resolved(.timedOut))
		let isResolved = await timer.isResolved
		XCTAssertTrue(isResolved)
	}

	enum TestResult: Equatable {
		case resolved(TimedResolution.Result)
		case error(any Error)

		static func == (lhs: TimedResolutionTests.TestResult, rhs: TimedResolutionTests.TestResult) -> Bool {
			switch lhs {
			case .resolved(let lhsResult):
				if case let .resolved(rhsResult) = rhs {
					lhsResult == rhsResult
				} else {
					false
				}
			case .error(let lhsError):
				if case .error(_) = rhs {
					true
				} else {
					false
				}
			}
		}
	}
}
