public extension Sequence where Element: BinaryInteger & UnsignedInteger {
	/// Creates a ``BitIterator`` from the collection.
	func makeBitIterator() -> BitIterator {
		.init(self)
	}
}
