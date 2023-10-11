public struct BitIterator<Number: BinaryInteger>: IteratorProtocol {
	public typealias Element = Bit

	var iterator: () -> Number?
	var current: Number?
	var position: Int = 0

	public init<C: Collection>(_ numbers: C) where C.Element == Number {
		var i = numbers.makeIterator()
		iterator = { i.next() }
	}

	public init(_ number: Number) {
		self.init([number])
	}

	public mutating func next() -> Bit? {
		if current == nil {
			current = iterator()
		}

		guard let current
		else { return nil }

		let bit = Bit(current, positionFromLeft: position)

		position += 1
		if position == current.bitWidth {
			self.current = nil
			position = 0
		}

		return bit
	}

	public mutating func next(_ count: Int) -> UInt? {
		var value: UInt = 0

		for position in (0..<count).reversed() {
			guard let next = next()
			else { return nil }

			value |= UInt(next.value) << position
		}

		return value
	}

	public mutating func next8() -> UInt8? {
		guard let val = next(8)
		else { return nil }
		return UInt8(truncatingIfNeeded: val)
	}

	public mutating func next16() -> UInt16? {
		guard let val = next(16)
		else { return nil }
		return UInt16(truncatingIfNeeded: val)
	}
}

public extension Collection where Element: BinaryInteger {
	func makeBitIterator() -> BitIterator<Element> {
		.init(self)
	}
}
