import Common
import Foundation
import OAuth2Models
import Vapor

/// Login tokens are automatically deleted when they are more than 12 hours old
private let loginExpirationLimit: TimeInterval = 86_400 / 2

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

struct Login: Codable {
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
	let coder = Coder()
	enum Error: Swift.Error {
		case usernameExists
		case cannotRemoveLastSysadmin
		case cannotRemoveLastAdmin
		case adminsCannotRemoveSysadmin
		case failedToStoreData
	}

	private struct UserData: Codable {
		var logins: [Login.ID: Login]
		var users: [User]
	}

	private let storagePath: String?
	private var data: UserData

	/// Creates a new UserData instance.
	///
	/// - parameter storagePath: The path to store the users at. If this is nil, users will not be persisted.
	init(storagePath: String?) throws {
		self.storagePath = storagePath

		var data: UserData? = nil
		if let storagePath {
			data = try Self.load(path: storagePath, coder: coder)
		}

		self.data = data ?? UserData(logins:
			[:],
			users: [
				User(username: "admin", password: "1234", scopes: [ .admin ]),
				User(username: "sys", password: "1234", scopes: [ .sysadmin ]),
				User(username: "regular", password: "1234", scopes: []),
			]
		)

		for (key, value) in self.data.logins {
			if value.expiresAt < .now {
				self.data.logins[key] = nil
			}
		}
	}

	private static let fm: FileManager = .default

	private static func load(path: String, coder: Coder) throws -> UserData? {
		guard let data = fm.contents(atPath: path)
		else { return nil }

		return try coder.decode(data)
	}

	private func save() throws {
		guard let storagePath
		else { return }

		let expiresLimit = Date.now - loginExpirationLimit
		data.logins = data.logins.filter({ expiresLimit < $0.value.expiresAt })

		let data = try coder.encode(data)
		guard Self.fm.createFile(atPath: storagePath, contents: data)
		else { throw Error.failedToStoreData }
	}

	func user(id: User.ID) -> User? {
		data.users.first { $0.id == id }
	}

	func user(username: String) -> User? {
		data.users.first { $0.username == username }
	}

	func remove(username: String, scopeOfCurrentUser: User.Scope) throws {
		guard let user = user(username: username)
		else { return }

		if user.scopes.contains(.sysadmin) {
			guard scopeOfCurrentUser == .sysadmin
			else { throw Error.adminsCannotRemoveSysadmin }

			guard data.users.filter({ $0.scopes.contains(.sysadmin) }).count > 1
			else { throw Error.cannotRemoveLastSysadmin }
		}

		if user.scopes.contains(.admin) && scopeOfCurrentUser != .sysadmin {
			guard data.users.filter({ $0.scopes.contains(.admin) }).count > 1
			else { throw Error.cannotRemoveLastAdmin }
		}

		data.users.removeAll { $0.username == username }

		try save()
	}

	func upsert(user: User, oldUsername: String) throws {
		guard user.username == oldUsername || !data.users.contains(where: { $0.username == user.username })
		else { throw Error.usernameExists }

		data.users.removeAll { $0.username == oldUsername }
		data.users.append(user)

		try save()
	}

	func users() -> [User] {
		users(includeSysAdmin: false)
	}

	func users(includeSysAdmin: Bool) -> [User] {
		if includeSysAdmin {
			data.users
		} else {
			data.users.filter { !$0.scopes.contains(.sysadmin) }
		}
	}

	func add(_ login: Login) throws {
		data.logins[login.id] = login
		try save()
	}

	func login(forToken token: String) -> (Login, User)? {
		guard
			let id = Login.id(forToken: token),
			let login = data.logins[id],
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
