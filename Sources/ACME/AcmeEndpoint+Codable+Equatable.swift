import AcmeSwift
import Foundation

extension AcmeEndpoint: @retroactive Equatable, Codable {
	public init(from decoder: any Swift.Decoder) throws {
		let url = try URL(from: decoder)

		if url == Self.letsEncrypt.value {
			self = .letsEncrypt
		} else if url == Self.letsEncryptStaging.value {
			self = .letsEncryptStaging
		} else {
			self = .custom(url)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		try value.encode(to: encoder)
	}

	public static func ==(lhs: AcmeEndpoint, rhs: AcmeEndpoint) -> Bool {
		lhs.value == rhs.value
	}
}
