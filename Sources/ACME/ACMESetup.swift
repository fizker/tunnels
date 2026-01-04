package import ACMEClientModels

package struct ACMESetup: Codable, Equatable, Hashable {
	package var host: String
	package var directory: ACMEDirectory
	package var contactEmail: String
	package var storagePath: String

	package init(host: String, directory: ACMEDirectory, contactEmail: String, storagePath: String) {
		self.host = host
		self.directory = directory
		self.contactEmail = contactEmail
		self.storagePath = storagePath
	}

	package enum Error: Swift.Error, CustomStringConvertible {
		/// Thrown during initialization if the existing data located at ``Setup/storagePath`` does not match ``endpoint``.
		case differentDirectoryInStoredData(ACMEDirectory)

		package var description: String {
			switch self {
			case let .differentDirectoryInStoredData(directory):
				"The stored data was initialized with the \(directory) directory"
			}
		}
	}
}
