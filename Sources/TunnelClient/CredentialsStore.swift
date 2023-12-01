import AsyncHTTPClient
import Foundation
import Models
import NIOHTTP1
import OAuth2Models

actor CredentialsStore {
	enum Error: Swift.Error {
		case noContent
		case invalidContentType(String)
	}

	private var credentials: ClientCredentials
	private var serverURL: URL
	private var accessToken: Result<(res: AccessTokenResponse, expires: Date), ErrorResponse>?

	init(credentials: ClientCredentials, serverURL: URL) {
		self.credentials = credentials
		self.serverURL = serverURL
	}

	func accessToken() async throws -> Result<AccessTokenResponse, ErrorResponse> {
		hasToken: if let accessToken {
			switch accessToken {
			case let .success(s):
				if s.expires <= .now {
					self.accessToken = nil
					break hasToken
				}
			case .failure(_):
				break
			}

			return accessToken.map(\.res)
		}

		let encoder = JSONEncoder()
		encoder.outputFormatting = .withoutEscapingSlashes

		let data = try encoder.encode(credentials.request)

		var request = HTTPClientRequest(url: serverURL.appending(path: "/auth/token").absoluteString)
		request.body = .bytes(.init(data: data))
		request.headers = ["content-type": "application/json"]
		request.method = .POST

		let client = HTTPClient()
		let response = try await client.execute(request, timeout: .seconds(30))

		do {
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

		let decoder = JSONDecoder()
		if let success = try? decoder.decode(AccessTokenResponse.self, from: content) {
			return .success(success)
		} else {
			return .failure(try decoder.decode(ErrorResponse.self, from: content))
		}
	}

	var httpHeaders: NIOHTTP1.HTTPHeaders {
		get async throws {
			let token = try await accessToken().get()
			let headerValue: String
			switch token.type {
			case .bearer: headerValue = "Bearer \(token.accessToken)"
			case .mac: fatalError("not implemented")
			}
			return ["authorization": headerValue]
		}
	}
}

extension ClientCredentials {
	var request: ClientCredentialsAccessTokenRequest {
		.init(clientID: clientID, clientSecret: clientSecret)
	}
}
