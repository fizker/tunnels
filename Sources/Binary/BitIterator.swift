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
public struct BitIterator<Number: BinaryInteger & UnsignedInteger>: IteratorProtocol {
	public typealias Element = Bit

	var iterator: () -> Number?
	var current: Number?
	var position: Int = 0

	/// Creates a new BitIterator that enumerates all bits in the given collection.
	public init<C: Collection>(_ numbers: C) where C.Element == Number {
		var i = numbers.makeIterator()
		iterator = { i.next() }
	}

	/// Creates a new BitIterator that enumerates all bits in the given number.
	public init(_ number: Number) {
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

	/// Advances to the next `count` ``Bit``s and returns an ``UInt`` with the read value, or `nil` if there are not `count` next element exists.
	///
	/// If the iterator has 4 bits remaining, and 5 bits are requested, the iterator is emptied and `nil` is returned.
	///
	/// if for example 4 bits are requested, and the next for bits are `0101`, the resulting value will be equivalent to `0b0101`.
	///
	/// - parameter count: The number of bits that should be read from the iterator.
	public mutating func next(_ count: Int) -> UInt? {
		var value: UInt = 0

		for position in (0..<count).reversed() {
			guard let next = next()
			else { return nil }

			value |= UInt(next.value) << position
		}

		return value
	}

	/// Advances to the next 8 ``Bit``s and returns an ``UInt8`` with the read value, or `nil` if there are not `count` next element exists.
	///
	/// If the iterator has less than 8 bits remaining, the iterator is emptied and `nil` is returned.
	public mutating func next8() -> UInt8? {
		guard let val = next(8)
		else { return nil }
		return UInt8(truncatingIfNeeded: val)
	}

	/// Advances to the next 16 ``Bit``s and returns an ``UInt16`` with the read value, or `nil` if there are not `count` next element exists.
	///
	/// If the iterator has less than 8 bits remaining, the iterator is emptied and `nil` is returned.
	public mutating func next16() -> UInt16? {
		guard let val = next(16)
		else { return nil }
		return UInt16(truncatingIfNeeded: val)
	}
}

public extension Collection where Element: BinaryInteger & UnsignedInteger {
	/// Creates a ``BitIterator`` from the collection.
	func makeBitIterator() -> BitIterator<Element> {
		.init(self)
	}
}
