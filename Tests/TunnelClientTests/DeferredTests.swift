import XCTest
@testable import TunnelClient

final class DeferredTests: XCTestCase {
	func test__resolve__singleResolve_syncResolve__resolvesAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")

		let actual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", actual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__resolve__multipleResolve_syncResolve__resolvesAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")
		deferred.resolve("bar")

		let actual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", actual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__reject__singleReject_sync__rejectsAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()

		do {
			_ = try await deferred.value
			XCTFail()
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		XCTAssertEqual(events, ["start", "resolving", "error caught"])
	}

	func test__reject__multipleReject_sync__rejectsAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()
		deferred.reject()

		do {
			_ = try await deferred.value
			XCTFail()
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		XCTAssertEqual(events, ["start", "resolving", "error caught"])
	}

	func test__resolve__rejectAfterResolve_sync__resolvesAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")
		deferred.reject()

		let actual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", actual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__reject__resolveAfterReject_sync__rejectsAsExpected() async throws {
		var deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()
		deferred.resolve("foo")

		do {
			_ = try await deferred.value
			XCTFail()
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		XCTAssertEqual(events, ["start", "resolving", "error caught"])
	}
}
