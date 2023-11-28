import Vapor

struct User {
	var username: String
}

actor UserStore {
	func user(username: String, password: String) -> User? {
		if username == "admin" && password == "1234" {
			User(username: "admin")
		} else {
			nil
		}
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
