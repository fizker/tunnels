import Foundation

public struct TunnelConfiguration: Codable, Sendable {
	public var host: String

	public init(host: String) {
		self.host = host
	}
}
