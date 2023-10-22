import Foundation

public struct TunnelConfiguration: Codable {
	public var host: String

	public init(host: String) {
		self.host = host
	}
}
