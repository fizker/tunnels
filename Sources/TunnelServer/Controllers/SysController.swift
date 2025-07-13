import ACME
import Vapor

class SysController {
	struct Setup: Codable, Content {
		var users: [User]
		var acmeData: ACMEData?
		var acmeSetup: ACMEHandler.Setup?
	}

	let request: Request
	let acmeHandler: ACMEHandler?
	let userStore: UserStore

	init(request: Request, acmeHandler: ACMEHandler? = nil, userStore: UserStore) {
		self.request = request
		self.acmeHandler = acmeHandler
		self.userStore = userStore
	}

	func setup() async -> Setup {
		return .init(
			users: await userStore.users(),
			acmeData: await acmeHandler?.acmeData,
			acmeSetup: await acmeHandler?.setup,
		)
	}
}

extension Request {
	func sysController() -> SysController {
		.init(request: self, acmeHandler: application.acmeHandler, userStore: application.userStore)
	}
}
