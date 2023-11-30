import Foundation
import OAuth2Models
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
}

struct Login {
	typealias ID = UUID

	var id: ID
	var userID: User.ID
	var loggedInAt: Date
	var expiresAt: Date

	init(id: ID = ID(), user: User, expiresIn: TokenExpiration = .oneHour) {
		self.id = id
		self.userID = user.id
		self.loggedInAt = .now
		self.expiresAt = expiresIn.date(in: .theFuture)
	}

	func accessTokenResponse(type: AccessTokenResponse.AccessTokenType) -> AccessTokenResponse {
		.init(
			accessToken: token,
			type: type,
			expiresIn: .seconds(Int(expiresAt.timeIntervalSinceNow))
		)
	}

	var token: String { id.uuidString }
	static func id(forToken token: String) -> ID? {
		ID(uuidString: token)
	}
}

actor UserStore {
	enum Error: Swift.Error {
		case usernameExists
		case cannotRemoveLastSysadmin
		case cannotRemoveLastAdmin
		case adminsCannotRemoveSysadmin
	}

	private var logins: [Login.ID: Login] = [:]

	private var users: [User] = [
		User(username: "admin", password: "1234", scopes: [ .admin ]),
		User(username: "sys", password: "1234", scopes: [ .sysadmin ]),
		User(username: "regular", password: "1234", scopes: []),
	]

	func user(id: User.ID) -> User? {
		users.first { $0.id == id }
	}

	func user(username: String) -> User? {
		users.first { $0.username == username }
	}

	func remove(username: String, scopeOfCurrentUser: User.Scope) throws {
		guard let user = user(username: username)
		else { return }

		if user.scopes.contains(.sysadmin) {
			guard scopeOfCurrentUser == .sysadmin
			else { throw Error.adminsCannotRemoveSysadmin }

			guard users.filter({ $0.scopes.contains(.sysadmin) }).count > 1
			else { throw Error.cannotRemoveLastSysadmin }
		}

		if user.scopes.contains(.admin) && scopeOfCurrentUser != .sysadmin {
			guard users.filter({ $0.scopes.contains(.admin) }).count > 1
			else { throw Error.cannotRemoveLastAdmin }
		}

		users.removeAll { $0.username == username }
	}

	func upsert(user: User, oldUsername: String) throws {
		guard user.username == oldUsername || !users.contains(where: { $0.username == user.username })
		else { throw Error.usernameExists }

		users.removeAll { $0.username == oldUsername }
		users.append(user)
	}

	func users(includeSysAdmin: Bool = false) -> [User] {
		if includeSysAdmin {
			self.users
		} else {
			self.users.filter { !$0.scopes.contains(.sysadmin) }
		}
	}

	func add(_ login: Login) {
		logins[login.id] = login
	}

	func login(forToken token: String) -> (Login, User)? {
		guard
			let id = Login.id(forToken: token),
			let login = logins[id],
			let user = user(id: login.userID)
		else { return nil }

		return (login, user)
	}
}

private struct UserStoreStorageKey: StorageKey {
	typealias Value = UserStore
}

extension Application {
	var userStore: UserStore {
		get { storage[UserStoreStorageKey.self]! }
		set { storage[UserStoreStorageKey.self] = newValue }
	}
}
