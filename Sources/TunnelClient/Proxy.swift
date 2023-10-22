import Models

public struct Proxy {
	public var localPort: Int
	public var host: String

	public init(localPort: Int, host: String) {
		self.localPort = localPort
		self.host = host
	}

	var config: TunnelConfiguration {
		.init(host: host)
	}
}
