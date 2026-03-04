import CompileSafeInitMacro
import FzkExtensions
import Testing
import VaporTesting
@testable import TunnelServer

struct SysControllerTests {
	typealias Setup = SysController.Setup

	let userWithScope = User(username: "scoped", password: "foo", scopes: [ .setupRead ])
	let userWithoutScope = User(username: "unscoped", password: "foo", scopes: [ ])

	let expectedETag = #""c2ba9b74f233305c9ddaaf0a6613d62fd89900d05bf9172b5506394a632ff7fe""#

	@Test
	func setup__noAuthHeaders__401IsReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.testing().test(.GET, "/sys/setup") { res in
				#expect(res.status == .init(statusCode: 401))
			}
		}
	}

	@Test
	func setup__userDoesNotHaveProperScope__403IsReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithoutScope)
			let headers = try await app.authHeader(for: userWithoutScope)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				#expect(res.status == .init(statusCode: 403))
			}
		}
	}

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

	@Test
	func setup__multipleQueries_knownHostsChangeInBetween_knownHostsNotIncluded__etagIsUnchanged() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope ~ {
				$0.add(.init(value: "example.com", lastSeen: #Date("2026-03-03T12:45:00Z")))
			})
			let headers = try await app.authHeader(for: userWithScope)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				try #require(res.status == .ok)
				let firstETag = res.headers["etag"]

				try await app.userStore.update(hosts: ["example.com"], for: userWithScope.id)

				try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
					try #require(res.status == .ok)

					let secondETag = res.headers["etag"]

					#expect(firstETag == secondETag)
				}
			}
		}
	}

	@Test
	func setup__multipleQueries_knownHostsChangeInBetween_knownHostsIncluded__etagIsDifferent() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope ~ {
				$0.add(.init(value: "example.com", lastSeen: #Date("2026-03-03T12:45:00Z")))
			})
			let headers = try await app.authHeader(for: userWithScope)

			try await app.testing().test(.GET, "/sys/setup?include-known-hosts", headers: headers) { res in
				try #require(res.status == .ok)
				let firstETag = res.headers["etag"]

				try await app.userStore.update(hosts: ["example.com"], for: userWithScope.id)

				try await app.testing().test(.GET, "/sys/setup?include-known-hosts", headers: headers) { res in
					try #require(res.status == .ok)

					let secondETag = res.headers["etag"]

					#expect(firstETag != secondETag)
				}
			}
		}
	}

	@Test
	func setup__noETag_knownHostsRegistered_knownHostsNotRequested__knownHostsAreNotReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			try await app.userStore.add(userWithScope ~ {
				$0.add(.init(value: "example.com", lastSeen: #Date("2026-03-03T12:45:00Z")))
			})

			let users = await app.userStore.users(includeSysAdmin: true).map(\.removingKnownHosts)

			let headers = try await app.authHeader(for: userWithScope)

			try await app.testing().test(.GET, "/sys/setup", headers: headers) { res in
				#expect(res.status == .ok)
				let setup = try res.content.decode(Setup.self)
				#expect(setup.users == users)
			}
		}
	}

	@Test
	func setup__noETag_knownHostsRegistered_knownHostsRequested__knownHostsAreReturned() async throws {
		try await withApp { app in
			try await configure(app, env: .empty)

			let userWithKnownHosts = userWithScope ~ {
				$0.add(.init(value: "example.com", lastSeen: #Date("2026-03-03T12:45:00Z")))
			}

			try await app.userStore.add(userWithKnownHosts)

			let users = await app.userStore.users(includeSysAdmin: true)

			let headers = try await app.authHeader(for: userWithScope)

			try await app.testing().test(.GET, "/sys/setup?include-known-hosts", headers: headers) { res in
				#expect(res.status == .ok)
				let setup = try res.content.decode(Setup.self)
				#expect(setup.users == users)
			}
		}
	}
}
