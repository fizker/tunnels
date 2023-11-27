import EnvironmentVariables
import Vapor

enum EnvVar: String, CaseIterable {
	case host
}

extension EnvironmentVariables where Key == EnvVar {
	var host: String {
		get {
			get(.host, default: "localhost")
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
