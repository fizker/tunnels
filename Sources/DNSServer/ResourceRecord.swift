import Binary

struct ResourceRecord {
	var name: DomainName
	var type: `Type`
	var `class`: Class
	var timeToLive: UInt32
	var length: UInt16

	init(name: DomainName, type: `Type`, `class`: Class, timeToLive: UInt32, length: UInt16) {
		self.name = name
		self.type = type
		self.class = `class`
		self.timeToLive = timeToLive
		self.length = length
	}

	init(iterator: inout BitIterator) throws {
		name = try .init(iterator: &iterator)

		guard
			let type = iterator.next16(),
			let `class` = iterator.next16(),
			let timeToLive = iterator.next32(),
			let length = iterator.next16()
		else { throw ParseError.endOfStream }

		self.type = .init(type)
		self.class = .init(`class`)
		self.timeToLive = timeToLive
		self.length = length
	}

	/// The class of the ResourceRecord.
	///
	/// | Class	| Value	| Meaning														|
	/// | -----		| ----		| -----															|
	/// | IN		| 1		| the Internet													|
	/// | CS		| 2		| the CSNET class (Obsolete - used only for examples in some obsolete RFCs)	|
	/// | CH		| 3		| the CHAOS class												|
	/// | HS		| 4		| Hesiod [Dyer 87]												|
	enum Class {
		/// the Internet
		case internet
		/// the CSNET class (Obsolete - used only for examples in some obsolete RFCs)
		case csnet
		/// the CHAOS class
		case chaos
		/// Hesiod [Dyer 87]
		case hesiod
		/// Catch-all for unknown classes
		case unknown(UInt16)

		init(_ value: UInt16) {
			switch value {
			case 1: self = .internet
			case 2: self = .csnet
			case 3: self = .chaos
			case 4: self = .hesiod
			default: self = .unknown(value)
			}
		}
	}

	/// The type of the ResourceRecord.
	///
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
			default: self = .unknown(value)
			}
		}
	}
}
