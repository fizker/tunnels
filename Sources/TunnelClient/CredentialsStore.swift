import AsyncHTTPClient
import Common
import Foundation
import Logging
import Models
import NIOHTTP1
import OAuth2Models

actor CredentialsStore {
	enum Error: Swift.Error {
		case noContent
		case invalidContentType(String)
		case invalidCredentials
	}

	private let logger = Logger(label: "CredentialsStore")
	private var credentials: ClientCredentials
	private var serverURL: URL
	private var accessToken: Result<(res: AccessTokenResponse, expires: Date), ErrorResponse>?
	private let coder = Coder()

	init(credentials: ClientCredentials, serverURL: URL) {
		self.credentials = credentials
		self.serverURL = serverURL
	}

	func accessToken() async throws -> Result<AccessTokenResponse, ErrorResponse> {
		hasToken: if let accessToken {
			switch accessToken {
			case let .success(s):
				if s.expires <= .now {
					logger.info("Existing token has expired. Discarding.")
					self.accessToken = nil
					break hasToken
				}
			case .failure(_):
				break
			}

			return accessToken.map(\.res)
		}

		let data = try coder.encode(credentials.request)

		var request = HTTPClientRequest(url: serverURL.appending(path: "/auth/token").absoluteString)
		request.body = .bytes(.init(data: data))
		request.headers = ["content-type": "application/json"]
		request.method = .POST

		let client = HTTPClient()

		do {
			logger.info("Requesting new AccessToken")
			let response = try await client.execute(request, timeout: .seconds(30))

			logger.debug("Received response. Parsing body")
			let result = try await parseBody(from: response)
			try await client.shutdown()

			accessToken = result.map { ($0, expirationDate($0.expiration)) }

			return result
		} catch {
			try await client.shutdown()
			throw error
		}
	}

	func expirationDate(_ ex: TokenExpiration?) -> Date {
		guard let ex
		else { return Date(timeIntervalSinceNow: 3600) }

		return ex.date(in: .theFuture) - TimeInterval(30)
	}

	func parseBody(from response: HTTPClientResponse) async throws -> Result<AccessTokenResponse, ErrorResponse> {
		guard
			let type = response.headers.first(name: "content-type")?.lowercased(),
			let length = response.headers.first(name: "content-length").flatMap(Int.init)
		else { throw Error.noContent }

		guard type.starts(with: "application/json")
		else { throw Error.invalidContentType(type) }

		var rawContent = try await response.body.collect(upTo: length)
		let content = rawContent.readData(length: length)!

		if let success = try? coder.decode(AccessTokenResponse.self, from: content) {
			logger.info("Response received. AccessToken was returned")
			return .success(success)
		} else {
			do {
				let error = try coder.decode(ErrorResponse.self, from: content)
				logger.error("Response received with OAuth2 error", metadata: [
					"error": "\(error)",
				])
				return .failure(error)
			} catch {
				logger.error("Response received with unknown body", metadata: [
					"error": "\(error)",
				])
				throw error
			}
		}
	}

	var httpHeaders: NIOHTTP1.HTTPHeaders {
		get async throws {
			switch try await accessToken() {
			case let .success(response):
				let headerValue: String
				switch response.type {
				case .bearer: headerValue = "Bearer \(response.accessToken)"
				case .mac: fatalError("not implemented")
				}
				return ["authorization": headerValue]
			case let .failure(response):
				switch response.code {
				case .invalidGrant, .invalidClient, .unauthorizedClient, .accessDenied:
					throw Error.invalidCredentials
				default:
					throw response
				}
			}
		}
	}
}

extension ClientCredentials {
	var request: ClientCredentialsAccessTokenRequest {
		.init(clientID: clientID, clientSecret: clientSecret)
	}
}
