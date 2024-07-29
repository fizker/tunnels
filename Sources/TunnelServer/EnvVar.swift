import AcmeSwift
import EnvironmentVariables
import Vapor

enum EnvVar: String, CaseIterable {
	case port = "PORT"
	case host
	case httpPort
	case useSSL
	case userStoragePath
	case acmeEndpoint
	case acmeContactEmail
	case acmeStoragePath
}

extension EnvironmentVariables where Key == EnvVar {
	var port: Int {
		get {
			get(.port, map: Int.init, default: 8110)
		}
	}

	var host: String {
		get {
			get(.host, default: "localhost")
		}
	}

	var httpPort: Int? {
		get {
			try? get(.httpPort, map: Int.init)
		}
	}

	var userStoragePath: String {
		get throws {
			try get(.userStoragePath)
		}
	}

	var useSSL: Bool {
		get {
			get(.useSSL, map: Bool.init, default: false)
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

	var acmeStoragePath: String {
		get throws {
			try get(.acmeStoragePath)
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
