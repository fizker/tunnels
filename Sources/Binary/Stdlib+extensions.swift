public extension RandomAccessCollection where Self: Sendable, Element: BitIterator.Number, Index == Int {
	/// Creates a ``BitIterator`` from the collection.
	func makeBitIterator() -> BitIterator {
		.init(self)
	}
}
