import Testing
import VaporTesting
@testable import TunnelServer

struct SysControllerTests {
	typealias Setup = SysController.Setup

	let userWithScope = User(username: "scoped", password: "foo", scopes: [ .setupRead ])
	let userWithoutScope = User(username: "unscoped", password: "foo", scopes: [ ])

	let expectedETag = #""c2ba9b74f233305c9ddaaf0a6613d62fd89900d05bf9172b5506394a632ff7fe""#

	@Test
	func setup__noETag_userHaveProperScope__setupIsReturned_etagIsReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope)
			let headers = try await app.authHeader(for: userWithScope)

			let users = await app.userStore.users(includeSysAdmin: true)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				#expect(res.status == .ok)
				let setup = try res.content.decode(Setup.self)
				#expect(setup.users == users)
				#expect(setup.acmeData == nil)
				#expect(setup.acmeSetup == nil)

				let etag = try #require(res.headers.first(name: "etag"))
				#expect(etag == expectedETag)
			}
		}
	}

	@Test
	func setup__etagGiven_etagDoesNotMatchCurrent_userHaveProperScope__setupIsReturned_etagIsReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope)
			var headers = try await app.authHeader(for: userWithScope)
			headers.replaceOrAdd(name: "etag", value: #""foo""#)

			let users = await app.userStore.users(includeSysAdmin: true)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				#expect(res.status == .ok)
				let setup = try res.content.decode(Setup.self)
				#expect(setup.users == users)
				#expect(setup.acmeData == nil)
				#expect(setup.acmeSetup == nil)

				let etag = try #require(res.headers.first(name: "etag"))
				#expect(etag == expectedETag)
			}
		}
	}

	@Test
	func setup__etagGiven_matchesCurrentETag__304IsReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope)
			var headers = try await app.authHeader(for: userWithScope)

			headers.replaceOrAdd(name: "etag", value: expectedETag)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				#expect(res.status == .notModified)
			}
		}
	}
}
