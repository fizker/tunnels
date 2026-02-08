import Foundation
import Vapor

struct User: Codable, Equatable, Sendable, Authenticatable {
	typealias ID = String

	var id: ID { username }

	var username: String
	var password: String
	var scopes: Set<Scope> = []

	var clientSecret: String? = nil
	var knownHosts: [String: KnownHost].Values {
		hostMap.values
	}
	private var hostMap: [String: KnownHost] = [:]

	init(username: String, password: String, scopes: Set<Scope> = [], clientSecret: String? = nil, knownHosts: [KnownHost] = []) {
		self.username = username
		self.password = password
		self.scopes = scopes
		self.clientSecret = clientSecret
		self.hostMap = .init(knownHosts.map {($0.value, $0)}) { a, b in
			a.lastSeen < b.lastSeen ? b : a
		}
	}

	mutating func add(_ host: KnownHost) {
		hostMap[host.value] = host
	}

	enum CodingKeys: CodingKey {
		case username
		case password
		case scopes
		case clientSecret
		case knownHosts
	}

	struct KnownHost: Codable, Hashable, Comparable {
		var value: String
		var lastSeen: Date

		func hash(into hasher: inout Hasher) {
			value.hash(into: &hasher)
		}

		static func <(lhs: Self, rhs: Self) -> Bool {
			return lhs.lastSeen < rhs.lastSeen
		}
	}

	enum Scope: String, CaseIterable, Codable, CustomStringConvertible, Comparable {
		case admin, sysadmin
		case setupRead

		var description: String {
			rawValue
		}

		/// The sort-value of the scope. A lower value means higher priority.
		var sortValue: Int {
			switch self {
			case .sysadmin: 1
			case .admin: 2
			case .setupRead: 3
			}
		}

		static func <(lhs: Scope, rhs: Scope) -> Bool {
			return lhs.sortValue < rhs.sortValue
		}
	}
}

extension User {
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		self.init(
			username: try container.decode(String.self, forKey: .username),
			password: try container.decode(String.self, forKey: .password),
			scopes: try container.decodeIfPresent(Set<User.Scope>.self, forKey: .scopes) ?? [],
			clientSecret: try container.decodeIfPresent(String.self, forKey: .clientSecret),
			knownHosts: try container.decodeIfPresent(Array<User.KnownHost>.self, forKey: .knownHosts) ?? []
		)
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(username, forKey: .username)
		try container.encode(password, forKey: .password)
		try container.encode(scopes.sorted(), forKey: .scopes)
		if let clientSecret {
			try container.encode(clientSecret, forKey: .clientSecret)
		}
		try container.encode(knownHosts.sorted(), forKey: .knownHosts)
	}
}

extension User: Hashable {
	func hash(into hasher: inout Hasher) {
		username.hash(into: &hasher)
		password.hash(into: &hasher)
		scopes.hash(into: &hasher)
		clientSecret.hash(into: &hasher)
		hostMap.hash(into: &hasher)
	}
}
