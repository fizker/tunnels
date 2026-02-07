import Testing
@testable import TunnelServer
import Foundation
import TunnelModels

struct UserTests {
	let coder = Coder()

	@Test
	func initFromDecoder__onlyUsernameAndPasswordIsSet__decodesCorrectly() async throws {
		let json = """
		{
			"username": "foo",
			"password": "bar"
		}
		"""

		let actual = try coder.decode(User.self, from: Data(json.utf8))

		let expected = User(username: "foo", password: "bar")

		#expect(actual == expected)
	}

	@Test
	func initFromDecoder__allValues__decodesCorrectly() async throws {
		let json = """
		{
			"username": "foo",
			"password": "bar",
			"scopes": [
				"admin",
				"sysadmin"
			],
			"clientSecret": "baz",
			"knownHosts": [
				{
					"lastSeen": "2024-11-12T12:34:56Z",
					"value": "example.com"
				},
				{
					"lastSeen": "2024-10-25T01:23:45Z",
					"value": "foo.example.com"
				}
			]
		}
		"""

		let actual = try coder.decode(User.self, from: Data(json.utf8))

		let expected = try User(
			username: "foo",
			password: "bar",
			scopes: [.admin, .sysadmin],
			clientSecret: "baz",
			knownHosts: [
				.init(value: "example.com", lastSeen: .init("2024-11-12T12:34:56Z", strategy: .iso8601)),
				.init(value: "foo.example.com", lastSeen: .init("2024-10-25T01:23:45Z", strategy: .iso8601)),
			]
		)

		#expect(actual == expected)
	}

	@Test
	func encodeToEncoder__onlyUsernameAndPasswordIsSet__encodesCorrectly() async throws {
		let json = """
		{
		  "knownHosts" : [

		  ],
		  "password" : "bar",
		  "scopes" : [

		  ],
		  "username" : "foo"
		}
		"""

		let user = User(username: "foo", password: "bar")

		let actual = try coder.encode(user)

		#expect(actual.asUTF8 == json)
	}

	@Test
	func encodeToEncoder__allValues__encodesCorrectly() async throws {
		let json = """
		{
		  "clientSecret" : "baz",
		  "knownHosts" : [
		    {
		      "lastSeen" : "2024-10-25T01:23:45Z",
		      "value" : "foo.example.com"
		    },
		    {
		      "lastSeen" : "2024-11-12T12:34:56Z",
		      "value" : "example.com"
		    }
		  ],
		  "password" : "bar",
		  "scopes" : [
		    "sysadmin",
		    "admin"
		  ],
		  "username" : "foo"
		}
		"""

		let user = try User(
			username: "foo",
			password: "bar",
			scopes: [.admin, .sysadmin],
			clientSecret: "baz",
			knownHosts: [
				.init(value: "foo.example.com", lastSeen: .init("2024-10-25T01:23:45Z", strategy: .iso8601)),
				.init(value: "example.com", lastSeen: .init("2024-11-12T12:34:56Z", strategy: .iso8601)),
			]
		)

		let actual = try coder.encode(user)

		#expect(actual.asUTF8 == json)
	}

	@Test
	func knownHosts__sameHost__onlyLatestHostIsAdded() async throws {
		var user = User(username: "foo", password: "bar")

		user.add(.init(value: "foo", lastSeen: .init(timeIntervalSinceNow: -20_000)))

		for i in stride(from: -20_000 as TimeInterval, to: 0, by: 200) {
			let date = Date(timeIntervalSinceNow: i)
			let new = User.KnownHost(value: "foo", lastSeen: date)
			user.add(new)
			#expect(Array(user.knownHosts) == [new])
			#expect(user.knownHosts.first?.lastSeen == date)
		}
	}
}

extension Data {
	var asUTF8: String? {
		String(data: self, encoding: .utf8)
	}
}
