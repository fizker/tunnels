import OAuth2Models
import Testing
@testable import TunnelServer

struct UserStoreTests {
	@Test
	func removeExpiredLogins__aMixOfExpiredAndNonExpired__valuesAreRemovedCorrectly() async throws {
		let store = try UserStore(storagePath: nil)

		let expirations: [TokenExpiration] = [
			.days(-10),
			.days(-5),
			.hours(-24),
			.hours(-11),
			.hours(-1),
		]

		let user = User(username: "foo", password: "bar")

		try await store.add(user)

		let logins = expirations.map { Login(user: user, expiresIn: $0) }

		for login in logins {
			try await store.add(login)
		}

		for login in logins {
			#expect(await store.login(forToken: login.token) != nil)
		}

		await store.removeExpiredLogins()

		for login in logins[..<3] {
			// These are expired
			#expect(await store.login(forToken: login.token) == nil)
		}

		for login in logins[3...] {
			// These are still valid
			#expect(await store.login(forToken: login.token) != nil)
		}
	}
}
