public enum DeferredError: Error, Sendable {
	case rejected
}

public class Deferred<T> {
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

	public func resolve(_ value: T) {
		guard state == nil
		else { return }

		state = .resolved(value)
		cont.yield(value)
		cont.finish()
	}

	public func reject() {
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
