import ACME
import Common
import FzkExtensions
import Vapor
import WebURL

actor ChallengeHandler: EndpointChallengeHandler {
	let host: String
	var isEnabled = false
	var pendingChallenges: [Challenge] = []

	init(host: String) {
		self.host = host
	}

	func enable() {
		isEnabled = true
	}

	func addTokenChallengeRoute(_ routes: Routes) {
		routes.get(".well-known", "acme-challenge", ":token") { req in
			guard let token = req.parameters.get("token")
			else { throw Abort(.notFound) }

			return try await self.challengeIssued(token: token)
		}
	}

	func register(challenge: PendingChallenge) async throws {
		guard isEnabled
		else { throw NotEnabledError() }

		let token = try token(for: challenge)
		let c = Challenge(token: token, value: challenge.value)

		pendingChallenges.append(c)

		_ = try await c.task.value
	}

	func remove(challenge: PendingChallenge) {
		guard let token = try? token(for: challenge)
		else { return }

		pendingChallenges.removeAll { $0.token == token }
	}

	private func token(for challenge: PendingChallenge) throws -> String {
		guard let url = WebURL(challenge.endpoint)
		else { throw InvalidChallengeEndpointError.invalidURL }
		guard url.host?.serialized == host
		else { throw InvalidChallengeEndpointError.invalidDomain }

		let components = url.pathComponents
		var wellKnownIndex = components.startIndex
		var challengeIndex = components.index(after: wellKnownIndex)
		var tokenIndex = components.index(after: challengeIndex)
		guard
			components[safe: wellKnownIndex] == ".well-known",
			components[safe: challengeIndex] == "acme-challenge",
			let token = components[safe: tokenIndex]
		else { throw InvalidChallengeEndpointError.invalidEndpoint }

		return token
	}

	private func challengeIssued(token: String) throws -> String {
		guard let match = pendingChallenges.first(where: { $0.token == token })
		else {
			print("Failed to resolve ACME challenge for token \(token)")
			throw Abort(.notFound)
		}

		match.task.resolve(())

		return match.value
	}

	struct Challenge {
		let token: String
		let value: String
		let task: Deferred<Void> = .init()
	}

	struct NotEnabledError: Error {}
	enum InvalidChallengeEndpointError: Error {
		case invalidURL
		case invalidDomain
		case invalidEndpoint
	}
}
