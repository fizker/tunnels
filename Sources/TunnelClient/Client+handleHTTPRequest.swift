import AsyncHTTPClient
import Foundation
import Models
import NIOCore

extension Client {
	func handle(_ req: HTTPRequest) async throws -> (response: HTTPResponse, bodyUploader: () async throws -> Void) {
		guard let proxy = proxies.first(where: { $0.host == req.host })
		else { throw ClientError.invalidHost(req.host) }

		let client = HTTPClient(configuration: .init(redirectConfiguration: .disallow))

		var request = HTTPClientRequest(url: "http://localhost:\(proxy.localPort)\(req.path)")
		request.method = .RAW(value: req.method)
		request.headers = .init(req.headers.flatMap { (key, values) in values.map { (key, $0) } })
		request.body = switch req.body {
		case let .text(text):
			.bytes(text.data(using: .utf8)!)
		case let .binary(data):
			.bytes(data)
		case .stream:
			try await stream(from: serverURL.appending(path: "tunnels/\(req.id)/request"), client: client)
		case nil:
			nil
		}

		do {
			let response = try await askProxy(request: request, client: client)
			let res = HTTPResponse(id: req.id, response: response)
			let uploadURL = serverURL.appending(path: "tunnels/\(req.id)/response")

			return (res, {
				if case .stream = res.body {
					try await self.upload(body: response, to: uploadURL, client: client)
				}
				try await client.shutdown()

			})
		} catch {
			try await client.shutdown()
			throw error
		}
	}

	private func askProxy(request: HTTPClientRequest, client: HTTPClient) async throws -> HTTPClientResponse {
		let timeout: TimeAmount = .minutes(10)
		do {
			return try await client.execute(request, timeout: timeout)
		} catch {
			if let error = error as? HTTPClient.NWPOSIXError {
				switch error.errorCode {
				case .ECONNREFUSED:
					let html = """
					<!doctype html>
					<h1>Service Unavailable</h1>
					<p>Proxied server did not respond.</p>
					"""
					return .init(status: .serviceUnavailable, headers: ["content-type": "text/html"], body: .bytes(.init(string: html)))
				default:
					logger.error("Failed to handle posix error \(error.errorCode)")
					break
				}
			} else if let error = error as? HTTPClientError {
				switch error {
				case .deadlineExceeded:
					let html = """
					<!doctype html>
					<h1>Gateway timed out</h1>
					<p>Timeout of \(timeout) exceeded.</p>
					"""
					return .init(status: .gatewayTimeout, headers: ["content-type": "text/html"], body: .bytes(.init(string: html)))
				case .remoteConnectionClosed:
					let html = """
					<!doctype html>
					<h1>Service Unavailable</h1>
					<p>Proxied server closed the connection before responding.</p>
					"""
					return .init(status: .serviceUnavailable, headers: ["content-type": "text/html"], body: .bytes(.init(string: html)))
				default:
					logger.error("Failed to handle HTTPClientError error \(error)")
					break
				}
			} else {
				logger.error("Unknown error: \(error)")
			}

			let html = """
			<!doctype html>
			<h1>Bad gateway</h1>
			<p>Unknown error returned.</p>
			"""
			return .init(status: .badGateway, headers: ["content-type": "text/html"], body: .bytes(.init(string: html)))
		}
	}

	func stream(from url: URL, client: HTTPClient) async throws -> HTTPClientRequest.Body {
		var request = HTTPClientRequest(url: url.absoluteString)
		request.headers = try await credentialsStore.httpHeaders

		let response = try await client.execute(request, timeout: .seconds(30))

		return .stream(response.body, length: .unknown)
	}

	func upload(body response: HTTPClientResponse, to url: URL, client: HTTPClient) async throws {
		var request = HTTPClientRequest(url: url.absoluteString)
		request.headers = try await credentialsStore.httpHeaders
		request.method = .POST
		request.body = .stream(response.body, length: .unknown)

		let response = try await client.execute(request, timeout: .seconds(30))
	}
}
