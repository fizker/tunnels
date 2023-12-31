import Models

public struct Proxy {
	public var localPort: Int
	public var host: String
	public var isReadyOnServer: Bool = false

	public init(localPort: Int, host: String) {
		self.localPort = localPort
		self.host = host
	}

	var config: TunnelConfiguration {
		.init(host: host)
	}
}
