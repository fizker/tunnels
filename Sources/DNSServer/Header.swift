import Binary

/// The header for the DNS Packet.
///
/// It has the following order
/// | RFC Name	| Descriptive Name	 	| Length	 	| Description	 |
/// |---------------------|-------------------------------------|---------------------|---------------------------------------|
/// | ID 			| Packet Identifier 		| 16 bits	 	| A random identifier is assigned to query packets. Response packets must reply with the same id. This is needed to differentiate responses due to the stateless nature of UDP. |
/// | QR 			| Query Response		| 1 bit			| 0 for queries, 1 for responses. |
/// | OPCODE		| Operation Code		| 4 bits		| Typically always 0, see RFC1035 for details. |
/// | AA			| Authoritative Answer		| 1 bit			| Set to 1 if the responding server is authoritative - that is, it "owns" - the domain queried. |
/// | TC			| Truncated Message		| 1 bit			| Set to 1 if the message length exceeds 512 bytes. Traditionally a hint that the query can be reissued using TCP, for which the length limitation doesn't apply. |
/// | RD			| Recursion Desired		| 1 bit			| Set by the sender of the request if the server should attempt to resolve the query recursively if it does not have an answer readily available. |
/// | RA			| Recursion Available		| 1 bit			| Set by the server to indicate whether or not recursive queries are allowed. |
/// | Z			| Reserved				| 3 bits		| Originally reserved for later use, but now used for DNSSEC queries. |
/// | RCODE		| Response Code		| 4 bits		| Set by the server to indicate the status of the response, i.e. whether or not it was successful or failed, and in the latter case providing details about the cause of the failure. |
/// | QDCOUNT	| Question Count		| 16 bits		| The number of entries in the Question Section |
/// | ANCOUNT	| Answer Count			| 16 bits		| The number of entries in the Answer Section |
/// | NSCOUNT	| Authority Count			| 16 bits		| The number of entries in the Authority Section |
/// | ARCOUNT	| Additional Count		| 16 bits		| The number of entries in the Additional Section |
struct Header {
	static let size = 12

	/// A random identifier is assigned to query packets. Response packets must reply with the same id. This is needed to differentiate responses due to the stateless nature of UDP.
	var id: UInt16
	var kind: Kind

	/// Typically always 0, see RFC1035 for details.
	var opcode: Opcode

	/// Set to 1 if the responding server is authoritative - that is, it "owns" - the domain queried.
	var isAuthoritativeAnswer: Bool
	/// Set to 1 if the message length exceeds 512 bytes. Traditionally a hint that the query can be reissued using TCP, for which the length limitation doesn't apply.
	var isTruncated: Bool
	/// Set by the sender of the request if the server should attempt to resolve the query recursively if it does not have an answer readily available.
	var isRecursionDesired: Bool
	/// Set by the server to indicate whether or not recursive queries are allowed.
	var isRecursionAvailable: Bool

	/// Set by the server to indicate the status of the response, i.e. whether or not it was successful or failed, and in the latter case providing details about the cause of the failure.
	var responseCode: UInt8

	/// The number of entries in the Question Section.
	var questionCount: UInt16
	/// The number of entries in the Answer Section.
	var answerCount: UInt16
	/// The number of entries in the Authority Section.
	var authorityCount: UInt16
	/// The number of entries in the Additional Section.
	var additionalCount: UInt16

	init(
		id: UInt16,
		kind: Kind,
		opcode: Opcode,
		isAuthoritativeAnswer: Bool,
		isTruncated: Bool,
		isRecursionDesired: Bool,
		isRecursionAvailable: Bool,
		responseCode: UInt8,
		questionCount: UInt16,
		answerCount: UInt16,
		authorityCount: UInt16,
		additionalCount: UInt16
	) {
		self.id = id
		self.kind = kind
		self.opcode = opcode
		self.isAuthoritativeAnswer = isAuthoritativeAnswer
		self.isTruncated = isTruncated
		self.isRecursionDesired = isRecursionDesired
		self.isRecursionAvailable = isRecursionAvailable
		self.responseCode = responseCode
		self.questionCount = questionCount
		self.answerCount = answerCount
		self.authorityCount = authorityCount
		self.additionalCount = additionalCount
	}

	init?<S: Sequence>(bytes: S) where S.Element == UInt8 {
		var iterator = bytes.makeBitIterator()
		guard
			let id = iterator.next16(),
			let kind = iterator.next(),
			let opcode = iterator.next(4),
			let isAuthoritativeAnswer = iterator.next(),
			let isTruncated = iterator.next(),
			let isRecursionDesired = iterator.next(),
			let isRecursionAvailable = iterator.next(),
			let responseCode = iterator.next8(),
			let questionCount = iterator.next16(),
			let answerCount = iterator.next16(),
			let authorityCount = iterator.next16(),
			let additionalCount = iterator.next16()
		else { return nil }

		self.init(
			id: id,
			kind: .init(kind),
			opcode: .init(.init(truncatingIfNeeded: opcode)),
			isAuthoritativeAnswer: isAuthoritativeAnswer == .one,
			isTruncated: isTruncated == .one,
			isRecursionDesired: isRecursionDesired == .one,
			isRecursionAvailable: isRecursionAvailable == .one,
			responseCode: responseCode,
			questionCount: questionCount,
			answerCount: answerCount,
			authorityCount: authorityCount,
			additionalCount: additionalCount
		)
	}

	enum Kind {
		case query, response

		/// Detects the kind of Packet from a ``Bit``.
		///
		/// 0 for queries, 1 for responses.
		init(_ bit: Bit) {
			self = switch bit {
			case .zero: .query
			case .one: .response
			}
		}
	}

	enum Opcode {
		case unknown(UInt8)

		init(_ value: UInt8) {
			self = .unknown(value)
		}
	}
}
