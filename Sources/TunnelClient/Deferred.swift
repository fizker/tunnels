public enum DeferredError: Error {
	case rejected
}

public class Deferred<T> {
	private var stream: AsyncStream<T>
	private var cont: AsyncStream<T>.Continuation

	public init(becoming type: T.Type = T.self) {
		var cont: AsyncStream<T>.Continuation!
		self.stream = AsyncStream {
			cont = $0
		}
		self.cont = cont
	}

	public func resolve(_ value: T) {
		cont.yield(value)
		cont.finish()
	}

	public func reject() {
		cont.finish()
	}

	public var value: T {
		get async throws {
			for await value in stream {
				return value
			}

			throw DeferredError.rejected
		}
	}
}
