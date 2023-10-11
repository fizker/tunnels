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
}
