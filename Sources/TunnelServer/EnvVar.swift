package import ACME
package import ACMEClientModels
package import EnvironmentVariables
import Foundation
package import SystemPackage
import TunnelModels
import Vapor

public enum EnvVar: String, CaseIterable, Sendable {
	case port = "PORT"
	case logs
	case host
	case httpPort
	case useSSL
	case userStoragePath
	case acmeSetup
	case acmeEndpoint
	case acmeContactEmail
	case acmeStoragePath
}

extension EnvironmentVariables where Key == EnvVar {
	package var port: Int {
		get {
			get(.port, map: Int.init, default: 8110)
		}
	}

	package var logs: FilePath {
		get {
			get(.logs, map: { FilePath($0) }, default: "server-logs")
		}
	}

	package var host: String {
		get {
			get(.host, default: "localhost")
		}
	}

	package var httpPort: Int? {
		get {
			try? get(.httpPort, map: Int.init)
		}
	}

	package var userStoragePath: String? {
		get {
			try? get(.userStoragePath)
		}
	}

	package var useSSL: Bool {
		get {
			get(.useSSL, map: Bool.init, default: false)
		}
	}

	package var useSelfSignedTLS: Bool {
		get {
			return useSSL
			&& (try? acmeDirectory) == nil
			&& (try? acmeContactEmail) == nil
			&& (try? acmeStoragePath) == nil
		}
	}

	package var acmeSetup: ACMESetup? {
		get throws {
			guard let acmeSetupPath = try? get(.acmeSetup)
			else {
				return useSSL
				? .init(
					host: host,
					directory: try acmeDirectory,
					contactEmail: try acmeContactEmail,
					storagePath: try acmeStoragePath,
				)
				: nil
			}

			let url = URL(fileURLWithPath: acmeSetupPath)
			let data = try Data(contentsOf: url)
			let coder = Coder()
			return try coder.decode(data)
		}
	}

	package var acmeContactEmail: String {
		get throws {
			try get(.acmeContactEmail)
		}
	}

	package var acmeDirectory: ACMEDirectory {
		get throws {
			try get(.acmeEndpoint) {
				switch $0 {
				case "production":
					.letsEncryptV2Production
				case "staging":
					.letsEncryptV2Staging
				default:
					nil
				}
			}
		}
	}

	package var acmeStoragePath: String {
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
