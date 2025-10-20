import Testing
@testable import TunnelClient

struct TimedResolutionTests {
	@Test
	func resolve__resolvesBeforeTimeout__resultIsResolved() async throws {
		let (stream, continuation) = AsyncStream.makeStream(of: TestResult.self)
		let timer = TimedResolution(timeout: .milliseconds(100)) { result in
			continuation.yield(.resolved(result))
		}

		Task.detached {
			do {
				try await Task.sleep(for: .milliseconds(50))
				timer.resolve()
			} catch {
				continuation.yield(.error(error))
			}
		}

		let result = await stream.first { _ in true }

		#expect(result == .resolved(.resolved))
		let isResolved = await timer.isResolved
		#expect(true == isResolved)
	}

	@Test
	func resolve__resolvesAfterTimeout__resultIsTimedOut() async throws {
		let (stream, continuation) = AsyncStream.makeStream(of: TestResult.self)
		let timer = TimedResolution(timeout: .milliseconds(100)) { result in
			continuation.yield(.resolved(result))
		}

		Task.detached {
			do {
				try await Task.sleep(for: .milliseconds(150))
				timer.resolve()
			} catch {
				continuation.yield(.error(error))
			}
		}

		let result = await stream.first { _ in true }

		#expect(result == .resolved(.timedOut))
		let isResolved = await timer.isResolved
		#expect(true == isResolved)
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
