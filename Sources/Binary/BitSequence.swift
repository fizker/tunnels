public extension Array where Element == Bit {
	/// Converts the given value to bits and appends them in order.
	mutating func append(_ value: any BitIterator.Number) {
		self.append(value, bits: value.bitWidth)
	}

	/// Converts the given value to bits and appends them in order.
	///
	/// Only the requested number of bits are added, counting from the least significant, as an easy way to add numbers of different size than UInt8, UInt16, etc.
	/// For example:
	/// ```swift
	/// var bits = [Bit]()
	/// bits.append(0b1001_1100, bits: 4)
	/// assert(bits == [1100])
	/// ```
	///
	/// - parameter bits: The number of bits that should be added.
	mutating func append(_ value: any BitIterator.Number, bits: Int) {
		var iterator = BitIterator(value)
		iterator.bitIndex = value.bitWidth - bits
		while let bit = iterator.next() {
			self.append(bit)
		}
	}

	/// Converts the given value to a Bit and appends it.
	mutating func append(_ value: Bool) {
		append(value.asBit)
	}
}
