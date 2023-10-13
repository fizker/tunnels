import Binary

struct QuestionRecord {
	var name: DomainName
	var type: `Type`
	var `class`: Class

	init(name: DomainName, type: `Type`, `class`: Class) {
		self.name = name
		self.type = type
		self.class = `class`
	}

	init(iterator: inout BitIterator) throws {
		name = try .init(iterator: &iterator)

		guard
			let type = iterator.next16(),
			let `class` = iterator.next16()
		else { throw ParseError.endOfStream }

		self.type = .init(type)
		self.class = .init(`class`)
	}

	/// The class of the QuestionRecord.
	///
	/// Note that this overlaps with most values of ``ResourceRecord/Class``, with some additional items.
	///
	/// | Class	| Value	| Meaning														|
	/// | -----		| ----		| -----															|
	/// | IN		| 1		| the Internet													|
	/// | CS		| 2		| the CSNET class (Obsolete - used only for examples in some obsolete RFCs)	|
	/// | CH		| 3		| the CHAOS class												|
	/// | HS		| 4		| Hesiod [Dyer 87]												|
	/// | \*		| 255		| any class 													|
	enum Class {
		/// the Internet
		case internet
		/// the CSNET class (Obsolete - used only for examples in some obsolete RFCs)
		case csnet
		/// the CHAOS class
		case chaos
		/// Hesiod [Dyer 87]
		case hesiod
		/// any class
		case anyClass
		/// Catch-all for unknown classes
		case unknown(UInt16)

		init(_ value: UInt16) {
			switch value {
			case 1: self = .internet
			case 2: self = .csnet
			case 3: self = .chaos
			case 4: self = .hesiod
			case 255: self = .anyClass
			default: self = .unknown(value)
			}
		}
	}

	/// The type of the QuestionRecord.
	///
	/// Note that this overlaps with most values of ``ResourceRecord/Type``, with some additional items.
	/// .
	/// | Type		| Value	| Meaning										|
	/// | ----			| ------	| -------										|
	/// | A			| 1		| a host address									|
	/// | NS			| 2		| an authoritative name server						|
	/// | MD			| 3		| a mail destination (Obsolete - use MX)				|
	/// | MF			| 4		| a mail forwarder (Obsolete - use MX)					|
	/// | CNAME		| 5		| the canonical name for an alias						|
	/// | SOA		| 6		| marks the start of a zone of authority					|
	/// | MB			| 7		| a mailbox domain name (EXPERIMENTAL)				|
	/// | MG			| 8		| a mail group member (EXPERIMENTAL)				|
	/// | MR			| 9		| a mail rename domain name (EXPERIMENTAL)			|
	/// | NULL		| 10		| a null RR (EXPERIMENTAL)						|
	/// | WKS		| 11		| a well known service description						|
	/// | PTR		| 12		| a domain name pointer							|
	/// | HINFO		| 13		| host information								|
	/// | MINFO		| 14		| mailbox or mail list information						|
	/// | MX			| 15		| mail exchange									|
	/// | TXT			| 16		| text strings									|
	/// | AXFR		| 252		| A request for a transfer of an entire zone				|
	/// | MAILB		| 253		| A request for mailbox-related records (MB, MG or MR)		|
	/// | MAILA		| 254		| A request for mail agent RRs (Obsolete - see MX)		|
	/// | \*			| 255		| A request for all records							|
	enum `Type` {
		/// A
		case hostAddress
		/// NS
		case authoritativeNameServer
		/// MD, Obsolete, use ``mailExchange`` (MX)
		@available(*, deprecated, renamed: "mailExchange", message: "Obsolete")
		case mailDestination
		/// MF, Obsolete, use ``mailExchange`` (MX)
		@available(*, deprecated, renamed: "mailExchange", message: "Obsolete")
		case mailForwarder
		/// CNAME
		case canonicalName
		/// SOA
		case zoneOfAuthority
		/// MB
		case mailboxDomainName
		/// MG
		case mailGroupMember
		/// MR
		case mailRenameDomain
		/// NULL
		case nullResourceRecord
		/// WKS
		case wellKnownService
		/// PTR
		case domainNamePointer
		/// HINFO
		case hostInformation
		/// MINFO
		case mailboxInformation
		/// MX
		case mailExchange
		/// TXT
		case textStrings
		/// AXFR
		case transferRequest
		/// MAILB
		case mailboxRelatedRecords
		/// MAILA, Obsolete, use ``mailExchange`` (MX)
		@available(*, deprecated, renamed: "mailExchange", message: "Obsolete")
		case mailAgentResourceRecords
		case allRecords
		case unknown(UInt16)

		init(_ value: UInt16) {
			switch value {
			case 1: self = .hostAddress
			case 2: self = .authoritativeNameServer
			case 3: self = .mailDestination
			case 4: self = .mailForwarder
			case 5: self = .canonicalName
			case 6: self = .zoneOfAuthority
			case 7: self = .mailboxDomainName
			case 8: self = .mailGroupMember
			case 9: self = .mailRenameDomain
			case 10: self = .nullResourceRecord
			case 11: self = .wellKnownService
			case 12: self = .domainNamePointer
			case 13: self = .hostInformation
			case 14: self = .mailboxInformation
			case 15: self = .mailExchange
			case 16: self = .textStrings
			case 252: self = .transferRequest
			case 253: self = .mailboxRelatedRecords
			case 254: self = .mailAgentResourceRecords
			case 255: self = .allRecords
			default: self = .unknown(value)
			}
		}
	}
}
