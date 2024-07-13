import AcmeSwift

package struct Setup: Codable {
	package var host: String
	package var endpoint: AcmeEndpoint
	package var contactEmail: String
	package var storagePath: String

	package init(host: String, endpoint: AcmeEndpoint, contactEmail: String, storagePath: String) {
		self.host = host
		self.endpoint = endpoint
		self.contactEmail = contactEmail
		self.storagePath = storagePath
	}

	package enum Error: Swift.Error, CustomStringConvertible {
		/// Thrown during initialization if the existing data located at ``Setup/storagePath`` does not match ``endpoint``.
		case differentEndpointInStoredData(AcmeEndpoint)

		package var description: String {
			switch self {
			case let .differentEndpointInStoredData(endpoint):
				"The stored data was initialized with the \(endpoint) endpoint"
			}
		}
	}
}
