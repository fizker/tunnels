import AcmeSwift
import EnvironmentVariables
import Vapor

enum EnvVar: String, CaseIterable {
	case host
	case acmeEndpoint
	case acmeContactEmail
}

extension EnvironmentVariables where Key == EnvVar {
	var host: String {
		get {
			get(.host, default: "localhost")
		}
	}

	var acmeContactEmail: String {
		get throws {
			try get(.acmeContactEmail)
		}
	}

	var acmeEndpoint: AcmeEndpoint {
		get throws {
			try get(.acmeEndpoint) {
				switch $0 {
				case "production":
					.letsEncrypt
				case "staging":
					.letsEncryptStaging
				default:
					nil
				}
			}
		}
	}
}

private struct EnvVarConfKey: StorageKey {
	typealias Value = EnvironmentVariables<EnvVar>
}

extension Application {
	var environment: EnvironmentVariables<EnvVar> {
		get { storage[EnvVarConfKey.self]! }
		set { storage[EnvVarConfKey.self] = newValue }
	}
}
