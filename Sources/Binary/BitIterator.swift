/// An iterator that enumerates the bits in one or more `BinaryInteger`.
///
/// It has some convenience methods for extracting multiple bits, on top of the protocol-required `next() -> Bit` function.
///
/// The convenience functions does not require anything from the content, other than it must contain at least the amount of bits that are requested.
///
/// For example
/// ```swift
/// var iterator = BitIterator(UInt8(145))
/// iterator.next(2)
/// iterator.next(3)
/// iterator.next(2)
/// // iterator will have one more bit to give
/// ```
public struct BitIterator: IteratorProtocol {
	public typealias Element = Bit
	public typealias Number = BinaryInteger & UnsignedInteger

	var iterator: () -> (any Number)?
	var current: (any Number)?
	var position: Int = 0

	/// Creates a new BitIterator that enumerates all bits in the given `Sequence`.
	public init<S: Sequence>(_ numbers: S) where S.Element: Number {
		var i = numbers.makeIterator()
		iterator = { i.next() }
	}

	/// Creates a new BitIterator that enumerates all bits in the given number.
	public init(_ number: some Number) {
		self.init([number])
	}

	/// Advances to the next ``Bit`` and returns it, or `nil` if no next element exists.
	public mutating func next() -> Bit? {
		if current == nil {
			current = iterator()
		}

		guard let current
		else { return nil }

		let bit = Bit(current, positionFromMostSignificant: position)

		position += 1
		if position == current.bitWidth {
			self.current = nil
			position = 0
		}

		return bit
	}
}
