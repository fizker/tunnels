public enum Bit {
	case zero
	case one

	public init<T: BinaryInteger>(_ value: T, position: Int) {
		guard position >= 0 && position < value.bitWidth
		else {
			self = .zero
			return
		}

		let shifted = value >> position
		let truncated = shifted & 1

		self = truncated == 0 ? .zero : .one
	}

	public init<T: BinaryInteger>(_ value: T, positionFromLeft: Int) {
		self.init(value, position: value.bitWidth - positionFromLeft - 1)
	}

	public var value: UInt8 {
		switch self {
		case .zero: 0
		case .one: 1
		}
	}
}
