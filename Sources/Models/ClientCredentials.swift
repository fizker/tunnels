public struct ClientCredentials: Codable {
	public var clientID: String
	public var clientSecret: String

	public init(clientID: String, clientSecret: String) {
		self.clientID = clientID
		self.clientSecret = clientSecret
	}
}
