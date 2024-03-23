import XCTest
@testable import Common

final class DeferredTests: XCTestCase {
	actor Events {
		var events: [String]

		init(_ events: [String]) {
			self.events = events
		}

		func append(_ value: String) {
			events.append(value)
		}
	}

	func test__resolve__singleResolve_syncResolve__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")

		let actual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", actual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__value__singleResolve_syncResolve_multipleValue__returnsTheSameValueEveryTime() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")

		let firstActual = try await deferred.value
		let secondActual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", firstActual)
		XCTAssertEqual("foo", secondActual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__resolve__multipleResolve_syncResolve__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")
		deferred.resolve("bar")

		let firstActual = try await deferred.value
		let secondActual = try await deferred.value
		events.append("after await")
		XCTAssertEqual("foo", firstActual)
		XCTAssertEqual("foo", secondActual)
		XCTAssertEqual(events, ["start", "resolving", "after await"])
	}

	func test__reject__singleReject_sync__rejectsAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

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
		let deferred = Deferred(becoming: String.self)

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
		let deferred = Deferred(becoming: String.self)

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
		let deferred = Deferred(becoming: String.self)

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

	func test__resolve__valueRequestedBeforeResolve__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		let events = Events(["start"])

		Task {
			try await Task.sleep(for: .milliseconds(100))
			await events.append("resolving")
			deferred.resolve("foo")
		}

		await events.append("requesting value")
		_ = try await deferred.value
		await events.append("value fetched")

		let e = await events.events
		XCTAssertEqual(e, ["start", "requesting value", "resolving", "value fetched"])
	}

	func test__reject__valueRequestedBeforeRejection__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		let events = Events(["start"])

		Task {
			try await Task.sleep(for: .milliseconds(100))
			await events.append("resolving")
			deferred.reject()
		}

		await events.append("requesting value")
		do {
			_ = try await deferred.value
			XCTFail()
		} catch DeferredError.rejected {
			await events.append("error caught")
		}

		let e = await events.events
		XCTAssertEqual(e, ["start", "requesting value", "resolving", "error caught"])
	}
}
