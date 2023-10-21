/// A single bit.
public enum Bit: CustomStringConvertible {
	case zero
	case one

	/// Returns the Bit at the given position of the given number.
	///
	/// The position is counted from least-significant, so index 0 would correspond to
	/// the bit with a value of 1 (`0b0000_0001`) and index 2 would have value 4 (`0b0000_0100`).
	///
	/// If the position is out of bounds, this always returns ``.zero``.
	///
	/// - parameter value: The full number.
	/// - parameter position: The position in the number.
	/// - returns: The Bit at the given position, or ``.zero`` if the position is out-of-bounds.
	public init<T: BinaryInteger & UnsignedInteger>(_ value: T, position: Int) {
		guard position >= 0 && position < value.bitWidth
		else {
			self = .zero
			return
		}

		let shifted = value >> position
		let truncated = shifted & 1

		self = truncated == 0 ? .zero : .one
	}

	/// Returns the Bit at the given position of the given number, counted from the most-significant bit.
	///
	/// The position is counted from most-significant, so for an 8-bit number, index 0 would correspond to
	/// the bit with a value of 127 (`0b1000_0000`) and index 2 would have value 4 (`0b0010_0000`).
	///
	/// If the position is out of bounds, this always returns ``.zero``.
	///
	/// - parameter value: The full number.
	/// - parameter positionFromMostSignificant: The position in the number.
	/// - returns: The Bit at the given position, or ``.zero`` if the position is out-of-bounds.
	public init<T: BinaryInteger & UnsignedInteger>(_ value: T, positionFromMostSignificant: Int) {
		self.init(value, position: value.bitWidth - positionFromMostSignificant - 1)
	}

	/// Returns a `UInt8` representation of this Bit.
	public var value: UInt8 {
		switch self {
		case .zero: 0
		case .one: 1
		}
	}

	/// Returns a `String` representation of this Bit.
	public var description: String {
		switch self {
		case .zero: "0"
		case .one: "1"
		}
	}
}
