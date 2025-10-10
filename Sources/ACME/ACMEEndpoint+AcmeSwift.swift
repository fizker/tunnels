package import AcmeSwift

package extension ACMEEndpoint {
	var asAcmeSwiftEndpoint: AcmeEndpoint {
		switch self {
		case .letsEncryptV2Production:
			return .letsEncrypt
		case .letsEncryptV2Staging:
			return .letsEncryptStaging
		}
	}
}
