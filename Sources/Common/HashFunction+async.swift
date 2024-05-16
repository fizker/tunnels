import Crypto
import Foundation

extension HashFunction {
	public static func digest<D: AsyncSequence>(stream: D) async rethrows -> Digest
		where D.Element == Data
	{
		var digester = Self()
		return try await digester.digest(stream: stream)
	}

	public mutating func digest<D: AsyncSequence>(stream: D) async rethrows -> Digest
		where D.Element == Data
	{
		for try await next in stream {
			update(data: next)
		}
		return finalize()
	}
}
