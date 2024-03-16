public struct ClientCredentials: Codable, Sendable {
	public var clientID: String
	public var clientSecret: String

	public init(clientID: String, clientSecret: String) {
		self.clientID = clientID
		self.clientSecret = clientSecret
	}
}
