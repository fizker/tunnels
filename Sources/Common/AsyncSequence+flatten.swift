extension AsyncSequence where Element: Sequence {
	public func flatten() -> AsyncFlatMapSequence<Self, AsyncStream<Self.Element.Element>> {
		self.flatMap {
			var iterator = $0.makeIterator()
			return AsyncStream { iterator.next() }
		}
	}
}
