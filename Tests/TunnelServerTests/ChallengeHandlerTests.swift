import ACMEAPIModels
@testable import ACMEClient
@testable import ACME
import CompileSafeInitMacro
import Testing
@testable import TunnelServer
import Vapor
import VaporTesting

@Suite(.serialized)
struct ChallengeHandlerTests {
	@Test
	func wellKnownACMEChallenge__validHTTPChallenge__returnsExpectedBody() async throws {
		try await withApp { app in
			let challengeHandler = ChallengeHandler(host: "example.com")
			await challengeHandler.addTokenChallengeRoute(app.routes)

			let token = challengeHandler.createToken()
			let privateKey = P256.PrivateKey()

			let identifier = Identifier(type: .dns, value: "")
			let challenge = Challenge(
				status: .pending,
				token: "foo",
				type: .http,
				url: #URL("https://example.com"),
			)
			let verification = try await challengeHandler.register(
				auth: .init(
					.init(
						identifier: identifier,
						status: .pending,
						challenges: [challenge],
					),
					url: #URL("https://auth.example.com/abc"),
					keyAuth: KeyAuthorization(publicKey: privateKey.publicKey),
				),
				token: token,
			)

			let httpChallenge: HTTPChallenge
			switch verification.challenge {
			case .dns:
				throw ChallengeError(message: "Challenge was DNS", type: verification.challenge.type)
			case .other:
				throw ChallengeError(message: "Challenge was other", type: verification.challenge.type)
			case let .http(c):
				httpChallenge = c
			}

			try await app.testing().test(.GET, httpChallenge.endpoint.path, body: httpChallenge.endpoint.body) { res in
				#expect(res.status == .ok)
				#expect(res.body.string == httpChallenge.endpoint.body)
			}
		}
	}

	struct ChallengeError: Error {
		var message: String
		var type: Challenge.`Type`
	}
}
