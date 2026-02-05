import ACME
import ACMEClientModels
import Common
import Crypto
import Vapor

class SysController {
	struct Setup: Codable, Content {
		var users: [User]
		var acmeData: ACMEData?
		var acmeSetup: ACMEHandler.Setup?
	}

	let request: Request
	let acmeHandler: ACMEHandler<ChallengeHandler>?
	let userStore: UserStore

	init(request: Request, acmeHandler: ACMEHandler<ChallengeHandler>? = nil, userStore: UserStore) {
		self.request = request
		self.acmeHandler = acmeHandler
		self.userStore = userStore
	}

	func setup() async throws -> Response {
		let setup = Setup(
			users: await userStore.users(includeSysAdmin: true),
			acmeData: await acmeHandler?.acmeData,
			acmeSetup: await acmeHandler?.setup,
		)

		let coder = Coder()
		let data = try coder.encode(setup)

		var digester = SHA256()
		digester.update(data: data)
		let digest = digester.finalize()

		let etag = #""\#(digest.hex)""#

		if request.headers.first(name: "etag") == etag {
			return Response(status: .notModified)
		}

		return Response(
			headers: ["content-type": "application/json", "etag":etag],
			body: .init(data: data),
		)
	}
}

extension Request {
	func sysController() -> SysController {
		.init(request: self, acmeHandler: application.acmeHandler, userStore: application.userStore)
	}
}
