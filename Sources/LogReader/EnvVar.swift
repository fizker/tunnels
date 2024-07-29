import EnvironmentVariables
import Vapor

enum EnvVar: String, CaseIterable {
	case storagePath = "storage_path"
	case port = "PORT"
}

extension EnvironmentVariables where Key == EnvVar {
	var storagePath: String {
		get throws {
			try get(.storagePath)
		}
	}

	var port: Int {
		get {
			get(.port, map: Int.init, default: 8112)
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
