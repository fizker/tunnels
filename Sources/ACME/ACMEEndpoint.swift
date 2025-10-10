package import Foundation
import FzkExtensions

package enum ACMEEndpoint: Equatable, Sendable {
	case letsEncryptV2Production
	case letsEncryptV2Staging
}

extension ACMEEndpoint: Codable {
	package init(from decoder: any Decoder) throws {
		enum CodingKeys: String, CodingKey {
			case relative
		}

		let rawValue: URL

		do {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			var allKeys = ArraySlice(container.allKeys)
			guard let onlyKey = allKeys.popFirst(), allKeys.isEmpty
			else {
				throw DecodingError.typeMismatch(
					ACMEEndpoint.self,
					DecodingError.Context.init(
						codingPath: container.codingPath,
						debugDescription: "Invalid number of keys found, expected one.",
						underlyingError: nil,
					)
				)
			}

			rawValue = try container.decode(URL.self, forKey: .relative)
		} catch {
			let container = try decoder.singleValueContainer()
			rawValue = try container.decode(URL.self)
		}

		self = try Self.init(rawValue: rawValue).unwrap()
	}

	package func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.rawValue)
	}
}

extension ACMEEndpoint: RawRepresentable {
	package init?(rawValue: URL) {
		switch rawValue {
		case Self.letsEncryptV2Staging.rawValue:
			self = .letsEncryptV2Staging
		case Self.letsEncryptV2Production.rawValue:
			self = .letsEncryptV2Production
		default: return nil
		}
	}

	package var rawValue: URL {
		switch self {
		case .letsEncryptV2Production: return URL(string: "https://acme-v02.api.letsencrypt.org/directory")!
		case .letsEncryptV2Staging: return URL(string: "https://acme-staging-v02.api.letsencrypt.org/directory")!
		}
	}
}
