import Foundation

/// Represents the errors that might occur while parsing the ``DNSPacket``.
enum ParseError: Error {
	/// The bytes did not add up to the expected count.
	case endOfStream
	/// The data extracted could not be parsed as ASCII.
	case notASCII(Data)
}
