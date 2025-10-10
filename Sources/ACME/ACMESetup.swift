package struct ACMESetup: Codable, Equatable {
	package var host: String
	package var endpoint: ACMEEndpoint
	package var contactEmail: String
	package var storagePath: String

	package init(host: String, endpoint: ACMEEndpoint, contactEmail: String, storagePath: String) {
		self.host = host
		self.endpoint = endpoint
		self.contactEmail = contactEmail
		self.storagePath = storagePath
	}

	package enum Error: Swift.Error, CustomStringConvertible {
		/// Thrown during initialization if the existing data located at ``Setup/storagePath`` does not match ``endpoint``.
		case differentEndpointInStoredData(ACMEEndpoint)

		package var description: String {
			switch self {
			case let .differentEndpointInStoredData(endpoint):
				"The stored data was initialized with the \(endpoint) endpoint"
			}
		}
	}
}
