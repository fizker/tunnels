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
public struct BitIterator: IteratorProtocol, Sendable {
	public typealias Element = Bit
	public typealias Number = BinaryInteger & UnsignedInteger & Sendable

	/// The bit width of ``Number``.
	let bitWidth: Int
	let currentFromIndex: @Sendable (Int) -> (any Number)?
	var current: (any Number)?
	var position: Int = 0
	var currentIndex: Int
	let startIndex: Int
	let endIndex: Int

	/// Creates a new BitIterator that enumerates all bits in the given `Sequence`.
	public init<S: RandomAccessCollection>(_ numbers: S) where S: Sendable, S.Element: Number, S.Index == Int {
		currentFromIndex = { $0 >= numbers.startIndex && $0 < numbers.endIndex ? numbers[$0] : nil }

		current = numbers.first
		bitWidth = current?.bitWidth ?? 0
		startIndex = numbers.startIndex
		endIndex = numbers.endIndex
		currentIndex = startIndex
	}

	/// Creates a new BitIterator that enumerates all bits in the given number.
	public init(_ number: some Number) {
		self.init([number])
	}

	/// Advances to the next ``Bit`` and returns it, or `nil` if no next element exists.
	public mutating func next() -> Bit? {
		if current == nil && currentIndex != endIndex {
			currentIndex += 1
			current = currentFromIndex(currentIndex)
			position = 0
		}

		guard let current
		else { return nil }


		let bit = Bit(current, positionFromMostSignificant: position)

		position += 1
		if position == bitWidth {
			self.current = nil
		}

		return bit
	}

	/// The current index of the bit iterator.
	///
	/// This is the index of the next bit to be returned by ``next()``.
	public var bitIndex: Int {
		get {
			let index = currentIndex - startIndex
			return index * bitWidth + position
		}
		set {
			guard bitWidth != 0
			else { return }

			// The remainder is found by relying on the flooring nature of integer arithmetics
			let currentIndex = newValue / bitWidth
			self.currentIndex = currentIndex + startIndex
			position = newValue - currentIndex * bitWidth
			current = currentFromIndex(self.currentIndex)
		}
	}

	/// The current index of the iterator, by counting full bytes from the start of the iterator.
	///
	/// **Note**: If the iterator is currently mid-byte (by advancing or setting the ``bitIndex`` to a value between full bytes),
	/// this value will be the index of the next full byte, thus it will skip forward.
	///
	/// For example:
	/// ```swift
	/// var iterator = BitIterator(0xdeadbeef as UInt32)
	/// _ = iterator.next(4)
	/// assert(4 == iterator.bitIndex)
	/// assert(1 == iterator.byteIndex) // the index of the next full byte
	///
	/// // we are now in effect skipping the remaining 4 bits of the first byte
	/// iterator.byteIndex = iterator.byteIndex
	/// assert(8 == iterator.bitIndex)
	/// ```
	/// This is the index of the next bit to be returned by ``next()``.
	public var byteIndex: Int {
		get {
			var index = bitIndex / 8
			if position % 8 != 0 {
				index += 1
			}
			return index
		}
		set { bitIndex = newValue * 8 }
	}

	/// Returns the bits available in the iterator.
	///
	/// This is the number of times that ``next()`` can be called before it returns `nil`.
	public var remainingBits: Int {
		let remainingUnits = endIndex - currentIndex
		let remainingUnitsAsBits = remainingUnits * bitWidth
		return remainingUnitsAsBits - position
	}

	/// Returns the full number of bytes available in the iterator.
	///
	/// This is the number of times that ``next8()`` can be called before it returns `nil`.
	public var remainingBytes: Int {
		remainingBits / 8
	}
}
