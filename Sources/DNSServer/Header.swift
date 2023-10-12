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
	var responseCode: ResponseCode?

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
		responseCode: ResponseCode?,
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
			let responseCode = iterator.next(4),
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
			responseCode: .init(value: responseCode),
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

	/// this 4 bit field is set as part of responses.  The values have the following interpretation:
	enum ResponseCode: Error {
		/// No error condition (0)
		//case success

		/// Format error (1)
		///
		/// The name server was unable to interpret the query.
		case formatError

		/// Server failure (2)
		///
		/// The name server was unable to process this query due to a problem with the name server.
		case serverFailure

		/// Name Error (3)
		///
		/// Meaningful only for responses from an authoritative name server, this code signifies that the
		/// domain name referenced in the query does not exist.
		case nameError

		/// Not Implemented (4)
		///
		/// The name server does not support the requested kind of query.
		case notImplemented

		/// Refused (5)
		///
		/// The name server refuses to perform the specified operation for policy reasons.
		/// For example, a name server may not wish to provide the information to the particular requester,
		/// or a name server may not wish to perform a particular operation (e.g., zone transfer) for particular data.
		case refused

		/// Reserved for future use. (6-15)
		case unknown(UInt)

		init?(value: UInt) {
			switch value {
			case 0: return nil
			case 1: self = .formatError
			case 2: self = .serverFailure
			case 3: self = .nameError
			case 4: self = .notImplemented
			case 5: self = .refused
			default: self = .unknown(value)
			}
		}
	}

	/// A four bit field that specifies kind of query in this message.  This value is set by the originator
	/// of a query and copied into the response.  The values are:
	enum Opcode {
		/// A standard query (0)
		case query

		/// An inverse query (1)
		case iquery

		/// A server status request (2)
		case status

		case unknown(UInt8)

		init(_ value: UInt8) {
			switch value {
			case 0: self = .query
			case 1: self = .iquery
			case 2: self = .status
			default: self = .unknown(value)
			}
		}
	}
}
