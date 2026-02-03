import ACME
import ACMEClient
import Common
import Foundation
import FzkExtensions
import Logging
import Vapor
import WebURL

actor ChallengeHandler: EndpointChallengeHandler {
	typealias Token = UUID
	let logger = Logger(label: "ChallengeHandler")
	let host: String
	var pendingChallenges: [(token: Token, challenge: TypedChallenge)] = []

	init(host: String) {
		self.host = host
	}

	func addTokenChallengeRoute(_ routes: Routes) {
		routes.get(".well-known", "acme-challenge", ":token") { req in
			guard let token = req.parameters.get("token")
			else { throw Abort(.notFound) }

			let pendingChallenges = await self.pendingChallenges
			let match = pendingChallenges.first(where: { $0.challenge.token == token })
			guard
				let match,
				case let .http(challenge) = match.challenge
			else {
				self.logger.info("Failed to resolve HTTP ACME challenge for token \(token)", metadata: [
					"match": "\(match?.challenge.type, default: "No match found")",
				])
				self.logger.debug("Available tokens: \(pendingChallenges.map(\.challenge.token))")
				throw Abort(.notFound)
			}

			return Response(
				status: .ok,
				headers: [
					"content-type": challenge.endpoint.contentType,
				],
				body: .init(string: challenge.endpoint.body),
			)
		}
	}

	nonisolated
	func createToken() -> Token {
		UUID()
	}

	func register(auth: TypedAuthorization, token: Token) async throws -> Verification {
		let verification: Verification
		if let v = auth.verify(via: .http) {
			verification = v
		} else if let v = auth.verify(via: .dns) {
			verification = v
		} else {
			throw UnsupportedChallengeType(types: auth.challenges.map(\.type))
		}

		logger.info("Registered challenge for \(verification.challenge.token)", metadata: [
			"token": "\(token)",
			"type": "\(verification.challenge.type)",
		])

		pendingChallenges.append((token, verification.challenge))
		return verification
	}

	func handleNonAutomaticSetup(token: Token) async throws {
		var hasDNS = false
		for pending in pendingChallenges where pending.token == token {
			switch pending.challenge {
			// Automatic setup
			case .http:
				break
			case let .dns(challenge):
				if !hasDNS {
					print("Setup DNS for the following challenges:")
				}
				hasDNS = true
				print(challenge.directions)
			case .other: break
			}
		}

		if hasDNS {
			print("Press enter to continue")
			_ = readLine()
		}
	}

	func reset(token: Token) {
		logger.info("Removing all challenges", metadata: [ "token": "\(token)" ])
		pendingChallenges.removeAll { $0.0 == token }
	}

	private func token(for challenge: PendingChallenge) throws -> String {
		guard let url = WebURL(challenge.endpoint)
		else { throw InvalidChallengeEndpointError.invalidURL }
		guard url.host?.serialized == host
		else { throw InvalidChallengeEndpointError.invalidDomain }

		let components = url.pathComponents
		let wellKnownIndex = components.startIndex
		let challengeIndex = components.index(after: wellKnownIndex)
		let tokenIndex = components.index(after: challengeIndex)
		guard
			components[safe: wellKnownIndex] == ".well-known",
			components[safe: challengeIndex] == "acme-challenge",
			let token = components[safe: tokenIndex]
		else { throw InvalidChallengeEndpointError.invalidEndpoint }

		return token
	}

	struct UnsupportedChallengeType: Error {
		var types: [TypedChallenge.`Type`]
	}
	enum InvalidChallengeEndpointError: Error {
		case invalidURL
		case invalidDomain
		case invalidEndpoint
	}
}
