public extension BinaryInteger where Self: UnsignedInteger {
	var asUInt8: [UInt8] {
		var bitWidth = bitWidth

		var output = [UInt8(truncatingIfNeeded: self)]

		var current = self
		while bitWidth > 8 {
			bitWidth -= 8
			current >>= 8
			output.append(.init(truncatingIfNeeded: current))
		}

#warning("The asUInt8 property does not support numbers whose bitWidth is not a complement of 8")

		return output.reversed()
	}
}

public extension Bool {
	var asBit: Bit {
		self ? .one : .zero
	}
}
