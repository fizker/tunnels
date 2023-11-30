import Foundation
import OAuth2Models
import Vapor

struct User: Codable, Authenticatable {
	enum Scope: String, Codable, CustomStringConvertible {
		case admin, sysadmin

		var description: String {
			rawValue
		}
	}

	var username: String
	var password: String
	var scopes: Set<Scope> = []
}

struct Login {
	typealias ID = UUID

	var id: ID
	var user: User
	var loggedInAt: Date
	var expiresAt: Date

	init(id: ID = ID(), user: User, expiresIn: TokenExpiration = .oneHour) {
		self.id = id
		self.user = user
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
	private var logins: [Login.ID: Login] = [:]

	private var users: [User] = [
		User(username: "admin", password: "1234", scopes: [ .admin ]),
		User(username: "sys", password: "1234", scopes: [ .sysadmin ]),
		User(username: "regular", password: "1234", scopes: []),
	]

	func user(username: String, password: String) -> User? {
		let user = users.first { $0.username == username }
		if user?.password == password {
			return user
		} else {
			return nil
		}
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

	func login(forToken token: String) -> Login? {
		guard let id = Login.id(forToken: token)
		else { return nil }

		return logins[id]
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
