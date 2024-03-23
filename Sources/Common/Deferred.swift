public enum DeferredError: Error, Sendable {
	case rejected
}

public actor Deferred<T: Sendable> {
	private enum State {
		case resolved(T)
		case rejected
	}

	private var state: State?
	private var stream: AsyncStream<T>
	private var cont: AsyncStream<T>.Continuation

	public init(becoming type: T.Type = T.self) {
		let v = AsyncStream.makeStream(of: T.self)
		self.stream = v.stream
		self.cont = v.continuation
	}

	public nonisolated func resolve(_ value: T) {
		Task {
			await _resolve(value)
		}
	}

	private func _resolve(_ value: T) {
		guard state == nil
		else { return }

		state = .resolved(value)
		cont.yield(value)
		cont.finish()
	}

	public nonisolated func reject() {
		Task {
			await _reject()
		}
	}

	private func _reject() {
		guard state == nil
		else { return }

		state = .rejected
		cont.finish()
	}

	public var value: T {
		get async throws {
			switch state {
			case let .resolved(value):
				return value
			case .rejected:
				throw DeferredError.rejected
			case nil:
				for await value in stream {
					return value
				}

				throw DeferredError.rejected
			}
		}
	}
}
