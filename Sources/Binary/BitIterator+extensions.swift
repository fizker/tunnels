import Foundation

extension IteratorProtocol where Element == Bit {
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
	/// If the iterator has less than 16 bits remaining, the iterator is emptied and `nil` is returned.
	public mutating func next16() -> UInt16? {
		guard let val = next(16)
		else { return nil }
		return UInt16(truncatingIfNeeded: val)
	}

	/// Advances to the next 32 ``Bit``s and returns an ``UInt32`` with the read value, or `nil` if there are not `count` next element exists.
	///
	/// If the iterator has less than 32 bits remaining, the iterator is emptied and `nil` is returned.
	public mutating func next32() -> UInt32? {
		guard let val = next(32)
		else { return nil }
		return .init(truncatingIfNeeded: val)
	}

	/// Reads the requested number of bytes, and accumulates then as a ``Foundation/Data``.
	///
	/// If the iteratr has less than the requested amount of bytes, `nil` is returned and the iterator is left empty.
	///
	/// - parameter bytes: The number of bytes to read.
	/// - returns: The accumulated `Data`, or `nil` if the bytes run out before `length` is reached.
	public mutating func data<T: BinaryInteger>(bytes: T) -> Data? {
		var data = Data()

		var count: T = 0
		while let byte = next8() {
			count += 1

			data.append(byte)

			if count == bytes {
				return data
			}
		}

		return nil
	}
}
