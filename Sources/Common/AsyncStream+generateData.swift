import Foundation

extension AsyncStream where Element == Data {
	public init(generateDataStreamOfSize size: Int, chunkSize: Int = 1024) {
		let a = Character("a").asciiValue!

		self.init { writer in
			var remainder = size
			for _ in stride(from: 0, to: size, by: chunkSize) {
				let toWrite = Swift.min(remainder, chunkSize)
				remainder -= toWrite
				writer.yield(Data(repeating: a, count: toWrite))
			}
			if remainder > 0 {
				writer.yield(Data(repeating: a, count: remainder))
			}
			writer.finish()
		}
	}
}
