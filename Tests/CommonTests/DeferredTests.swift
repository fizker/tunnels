import Testing
@testable import Common

struct DeferredTests {
	actor Events {
		var events: [String]

		init(_ events: [String]) {
			self.events = events
		}

		func append(_ value: String) {
			events.append(value)
		}
	}

	@Test
	func resolve__singleResolve_syncResolve__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")

		let actual = try await deferred.value
		events.append("after await")
		#expect("foo" == actual)
		#expect(events == ["start", "resolving", "after await"])
	}

	@Test
	func value__singleResolve_syncResolve_multipleValue__returnsTheSameValueEveryTime() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")

		let firstActual = try await deferred.value
		let secondActual = try await deferred.value
		events.append("after await")
		#expect("foo" == firstActual)
		#expect("foo" == secondActual)
		#expect(events == ["start", "resolving", "after await"])
	}

	@Test
	func resolve__multipleResolve_syncResolve__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")
		try await waitToStabilize()
		deferred.resolve("bar")
		try await waitToStabilize()

		let firstActual = try await deferred.value
		let secondActual = try await deferred.value
		events.append("after await")
		#expect("foo" == firstActual)
		#expect("foo" == secondActual)
		#expect(events == ["start", "resolving", "after await"])
	}

	@Test
	func reject__singleReject_sync__rejectsAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()

		do {
			_ = try await deferred.value
			#expect(Bool(false))
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		#expect(events == ["start", "resolving", "error caught"])
	}

	@Test
	func reject__multipleReject_sync__rejectsAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()
		deferred.reject()

		do {
			_ = try await deferred.value
			#expect(Bool(false))
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		#expect(events == ["start", "resolving", "error caught"])
	}

	@Test
	func resolve__rejectAfterResolve_sync__resolvesAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.resolve("foo")
		try await waitToStabilize()
		deferred.reject()
		try await waitToStabilize()

		let actual = try await deferred.value
		events.append("after await")
		#expect("foo" == actual)
		#expect(events == ["start", "resolving", "after await"])
	}

	@Test
	func reject__resolveAfterReject_sync__rejectsAsExpected() async throws {
		let deferred = Deferred(becoming: String.self)

		var events = ["start"]

		events.append("resolving")
		deferred.reject()
		try await waitToStabilize()
		deferred.resolve("foo")
		try await waitToStabilize()

		do {
			_ = try await deferred.value
			#expect(Bool(false))
		} catch DeferredError.rejected {
			events.append("error caught")
		}

		#expect(events == ["start", "resolving", "error caught"])
	}

	@Test
	func resolve__valueRequestedBeforeResolve__resolvesAsExpected() async throws {
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
		#expect(e == ["start", "requesting value", "resolving", "value fetched"])
	}

	@Test
	func reject__valueRequestedBeforeRejection__resolvesAsExpected() async throws {
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
			#expect(Bool(false))
		} catch DeferredError.rejected {
			await events.append("error caught")
		}

		let e = await events.events
		#expect(e == ["start", "requesting value", "resolving", "error caught"])
	}

	/// `deferred.resolve()`/`deferred.reject()` is running in a Task, and we want to ensure that it has a chance to complete
	func waitToStabilize() async throws {
		try await Task.sleep(for: .milliseconds(10))
	}
}
