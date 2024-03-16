import Vapor

public struct UpgradeResponse: Sendable {
	/// The host to upgrade to. If this is `nil`, the host will be kept unchanged.
	public var host: String? = nil

	/// The port to upgrade to.
	public var port: Int = 443

	public var isRejected: Bool = false
	public var isAccepted: Bool {
		get { !isRejected }
		set { isRejected = !newValue }
	}

	/// Accepts the upgrade using the original host and standard HTTPS port (443).
	public static var accepted: Self {
		.init()
	}

	/// Accepts the upgrade using the given host and optional port (defaults to 443).
	///
	/// - parameter host: The host to redirect to.
	/// - parameter port: The port to redirect to. If this is not given, the default HTTPS port will be used (443).
	public static func accepted(host: String, port: Int = 443) -> Self {
		.init(host: host, port: port)
	}

	/// Accepts the upgrade with the original host and a custom port.
	///
	/// - parameter port: The port to use in the redirect.
	public static func accepted(port: Int) -> Self {
		.init(port: port)
	}

	/// Rejects the upgrade.
	public static var rejected: Self {
		.init(isRejected: true)
	}
}

/// A function that tests a host and returns an ``UpgradeResponse`` to denote if it should be upgraded or be rejected.
public typealias UpgradeRequest = @Sendable (String) async -> UpgradeResponse

struct UpgradeMiddleware: AsyncMiddleware {
	var requestUpgrade: UpgradeRequest

	func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
		var url = request.url
		url.scheme = "https"

		guard let host = request.headers["host"].first
		else { return Response(status: .serviceUnavailable) }

		let response = await requestUpgrade(host)
		guard response.isAccepted
		else { return Response(status: .serviceUnavailable) }

		url.host = response.host ?? host
		url.port = response.port == 443 ? nil : response.port

		return Response(
			status: .temporaryRedirect,
			headers: [
				"location": "\(url)",
			]
		)
	}
}
