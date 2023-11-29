import Foundation
import OAuth2Models
import Vapor

struct User: Authenticatable {
	var username: String
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

	func user(username: String, password: String) -> User? {
		if username == "admin" && password == "1234" {
			User(username: "admin")
		} else {
			nil
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
