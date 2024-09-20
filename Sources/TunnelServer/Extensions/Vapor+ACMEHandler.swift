import ACME
import Vapor

private struct ACMEHandlerStorageKey: StorageKey {
	typealias Value = ACMEHandler
}

extension Application {
	var acmeHandler: ACMEHandler? {
		get { storage[ACMEHandlerStorageKey.self] }
		set { storage[ACMEHandlerStorageKey.self] = newValue }
	}
}
