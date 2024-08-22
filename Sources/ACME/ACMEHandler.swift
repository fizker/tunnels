import Common
import Foundation

package actor ACMEHandler {
	package typealias Setup = ACMESetup

	var registeredEndpoints: Set<String> = []
	var acmeData: ACMEData
	let coder = Coder()
	let setup: Setup

	package init(setup: Setup) throws {
		self.setup = setup

		let fm = FileManager.default
		if let data = fm.contents(atPath: setup.storagePath) {
			acmeData = try coder.decode(data)

			guard setup.endpoint == acmeData.endpoint
			else { throw Setup.Error.differentEndpointInStoredData(acmeData.endpoint) }
		} else {
			acmeData = .init(endpoint: setup.endpoint)
		}

		#warning("TODO: Check if the certificate is ready for renewal and set up timer for when it needs renewal")
	}

	package func register(endpoint: String) {
		register(endpoints: [endpoint])
	}

	package func register(endpoints: [String]) {
		registeredEndpoints.formUnion(endpoints)

		if !(acmeData.certificates?.covers(domains: endpoints) ?? false) {
			#warning("TODO: Update certificate")
			print("Updating certificates")
		}
	}

	private func save() throws {
		let data = try coder.encode(acmeData)
		try data.write(to: URL(filePath: setup.storagePath))
	}
}
