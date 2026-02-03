import ACME
import Vapor

private struct ACMEHandlerStorageKey: StorageKey {
	typealias Value = ACMEHandler<ChallengeHandler>
}

extension Application {
	var acmeHandler: ACMEHandler<ChallengeHandler>? {
		get { storage[ACMEHandlerStorageKey.self] }
		set { storage[ACMEHandlerStorageKey.self] = newValue }
	}
}
