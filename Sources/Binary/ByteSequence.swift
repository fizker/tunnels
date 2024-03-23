/// A Sequence of UInt8 wrapping a BitIterator.
///
/// This is compatible with the `Data(contentsOf:)` initializer.
public struct ByteSequence: Sequence, Sendable {
	public struct Iterator: IteratorProtocol, Sendable {
		public typealias Element = UInt8

		var bitIterator: BitIterator

		public mutating func next() -> UInt8? {
			bitIterator.next8()
		}
	}

	public typealias Element = UInt8

	var bitIterator: BitIterator

	public init(bitIterator: BitIterator) {
		self.bitIterator = bitIterator
	}

	public func makeIterator() -> Iterator {
		Iterator(bitIterator: bitIterator)
	}
}

extension BitIterator {
	/// Returns a Sequence of UInt8. This sequence contains a copy of the current iterator; enumerating the sequence will not affect the current iterator.
	///
	/// This is compatible with the `Data(contentsOf:)` initializer.
	public var byteSequence: ByteSequence {
		ByteSequence(bitIterator: self)
	}
}
