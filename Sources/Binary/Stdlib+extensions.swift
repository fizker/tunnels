public extension RandomAccessCollection where Element: BinaryInteger & UnsignedInteger, Index == Int {
	/// Creates a ``BitIterator`` from the collection.
	func makeBitIterator() -> BitIterator {
		.init(self)
	}
}
