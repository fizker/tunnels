package import ACMEClientModels

package struct ACMESetup: Codable, Equatable, Hashable {
	package var host: String
	package var directory: ACMEDirectory
	package var contactEmail: String
	package var storagePath: String
	package var fetchCertificates: Bool

	package init(
		host: String,
		directory: ACMEDirectory,
		contactEmail: String,
		storagePath: String,
		fetchCertificates: Bool = true,
	) {
		self.host = host
		self.directory = directory
		self.contactEmail = contactEmail
		self.storagePath = storagePath
		self.fetchCertificates = fetchCertificates
	}

	package init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.host = try container.decode(String.self, forKey: .host)
		self.directory = try container.decode(ACMEDirectory.self, forKey: .directory)
		self.contactEmail = try container.decode(String.self, forKey: .contactEmail)
		self.storagePath = try container.decode(String.self, forKey: .storagePath)
		self.fetchCertificates = try container.decodeIfPresent(Bool.self, forKey: .fetchCertificates) ?? true
	}

	package func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.host, forKey: .host)
		try container.encode(self.directory, forKey: .directory)
		try container.encode(self.contactEmail, forKey: .contactEmail)
		try container.encode(self.storagePath, forKey: .storagePath)
		if !fetchCertificates {
			try container.encode(self.fetchCertificates, forKey: .fetchCertificates)
		}
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

	enum CodingKeys: CodingKey {
		case host
		case directory
		case contactEmail
		case storagePath
		case fetchCertificates
	}
}
