import Foundation
import Vapor

struct User: Codable, Equatable, Authenticatable {
	enum Scope: String, Codable, CustomStringConvertible, Comparable {
		case admin, sysadmin

		var description: String {
			rawValue
		}

		static func <(lhs: Scope, rhs: Scope) -> Bool {
			switch (lhs, rhs) {
			case (.admin, .admin), (.sysadmin, .sysadmin):
				false
			case (.admin, .sysadmin):
				false
			case (.sysadmin, .admin):
				true
			}
		}
	}

	typealias ID = String

	var id: ID { username }

	var username: String
	var password: String
	var scopes: Set<Scope> = []

	var clientSecret: String? = nil
	var knownHosts: Set<KnownHost> = []

	struct KnownHost: Codable, Hashable {
		var value: String
		var lastSeen: Date

		func hash(into hasher: inout Hasher) {
			value.hash(into: &hasher)
		}
	}
}

extension User {
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.username = try container.decode(String.self, forKey: .username)
		self.password = try container.decode(String.self, forKey: .password)
		self.scopes = try container.decodeIfPresent(Set<User.Scope>.self, forKey: .scopes) ?? []
		self.clientSecret = try container.decodeIfPresent(String.self, forKey: .clientSecret)
		self.knownHosts = try container.decodeIfPresent(Set<User.KnownHost>.self, forKey: .knownHosts) ?? []
	}
}
