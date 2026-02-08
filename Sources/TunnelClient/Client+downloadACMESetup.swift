import AsyncHTTPClient
import Foundation
import FzkExtensions
import NIOHTTP1
import WebURL

extension Client {
	func downloadACMESetup(downloadPath: WebURL, authHeader: HTTPHeaders) async throws {
		var etagPath = downloadPath
		etagPath.path += ".etag"
		let etagData = try? Data(contentsOf: etagPath)
		let etag = etagData
			.flatMap { String(data: $0, encoding: .utf8) }?
			.trimmingCharacters(in: .whitespacesAndNewlines)
		logger.info("Asking server for ACME setup data", metadata: [
			"etag": "\(etag, default: "N/A")"
		])

		let client = HTTPClient()
		let url = serverURL.appending(path: ["sys", "setup"])
		let request = HTTPClientRequest(url: url.serialized()) ~ {
			$0.headers.add(contentsOf: authHeader)
			if let etag {
				$0.headers.replaceOrAdd(name: "etag", value: etag)
			}
		}
		let response = try await client.execute(request, timeout: .seconds(20))
		if response.status == .ok {
			let etag = response.headers.first(name: "etag")?.data(using: .utf8)
			let body = try await response.body.collectAll() as Data

			try body.write(to: downloadPath)
			try etag?.write(to: etagPath)

			logger.info("New ACME data downloaded")
		} else if response.status == .notModified {
			logger.info("ACME data up-to-date")
		} else if response.status == .forbidden {
			logger.error("The current user does not have access to the ACME setup")
		} else {
			logger.error("Unexpected status code from ACME setup endpoint", metadata: [
				"status": "\(response.status)",
			])
		}
		try await client.shutdown()
	}
}

private extension HTTPClientResponse.Body {
	func collectAll() async throws -> Data {
		var data = Data()
		for try await buffer in self {
			data.append(contentsOf: buffer.readableBytesView)
		}
		return data
	}
}
