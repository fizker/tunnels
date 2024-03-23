actor TimedResolution {
	enum Result {
		case resolved, timedOut

		var isSuccess: Bool {
			switch self {
			case .resolved: true
			case .timedOut: false
			}
		}
	}

	private(set) var isResolved = false
	let timeout: Duration
	let onEnd: @Sendable (Result) async -> ()

	init(timeout: Duration, onEnd: @escaping @Sendable (Result) async -> Void) {
		self.timeout = timeout
		self.onEnd = onEnd

		Task.detached {
			try await Task.sleep(for: timeout)
			self.timeOut()
		}
	}

	nonisolated func resolve() {
		Task {
			await resolve(with: .resolved)
		}
	}

	nonisolated func timeOut() {
		Task {
			await resolve(with: .timedOut)
		}
	}

	private func resolve(with result: Result) {
		guard !isResolved
		else { return }
		isResolved = true
		Task.detached {
			await self.onEnd(result)
		}
	}
}
