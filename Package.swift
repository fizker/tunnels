// swift-tools-version: 6.2
import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
	.enableUpcomingFeature("ExistentialAny"),
	.enableExperimentalFeature("StrictConcurrency"),
	.enableExperimentalFeature("AccessLevelOnImport"),
	.enableUpcomingFeature("InternalImportsByDefault"),
	.enableUpcomingFeature("FullTypedThrows"),
]

let package = Package(
	name: "tunnels",
	platforms: [ .macOS(.v13) ],
	products: [
		.executable(name: "debug-server", targets: ["DebugServerCLI"]),
		.executable(name: "dns-server", targets: ["DNSServerCLI"]),
		.executable(name: "tunnel-client", targets: ["TunnelClientCLI"]),
		.executable(name: "tunnel-server", targets: ["TunnelServerCLI"]),
		.executable(name: "tunnel-logs", targets: ["LogReader"]),
	],
	dependencies: [
		.package(url: "https://github.com/fizker/tunnels-models.git", branch: "main"),
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
		.package(url: "https://github.com/apple/swift-asn1.git", from: "1.4.0"),
		// TODO: Bump swift-crypto to 4.0 when swift-certificates updates to allow that
		.package(url: "https://github.com/apple/swift-certificates.git", from: "1.14.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", from: "3.15.1"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.86.2"),
		.package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.34.1"),
		.package(url: "https://github.com/fizker/swift-environment-variables.git", from: "1.1.1"),
		.package(url: "https://github.com/fizker/swift-extensions.git", from:"1.4.0"),
		.package(url: "https://github.com/fizker/swift-oauth2-models.git", .upToNextMinor(from: "0.4.0")),
		.package(url: "https://github.com/karwa/swift-url.git", .upToNextMinor(from: "0.4.2")),
		.package(url: "https://github.com/m-barthelemy/AcmeSwift.git", from: "1.0.0-beta6"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.29.0"),
//		.package(url: "https://github.com/vapor/vapor.git", from: "4.117.0"),
		.package(url: "https://github.com/fizker/vapor.git", branch: "make-RouteNotFound-public"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.16.1"),
	],
	targets: [
		.target(
			name: "ACME",
			dependencies: [
				"Common",
				.product(name: "AcmeSwift", package: "acmeswift"),
				.product(name: "SwiftASN1", package: "swift-asn1"),
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "X509", package: "swift-certificates"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "Binary",
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "CatchAll",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "Common",
			dependencies: [
				.product(name: "Crypto", package: "swift-crypto"),
				.product(name: "FzkExtensions", package: "swift-extensions"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "DNSServer",
			dependencies: [
				"Binary",
				.product(name: "NIO", package: "swift-nio"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "HTTPUpgradeServer",
			dependencies: [
				"CatchAll",
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "WebSocket",
			dependencies: [
				"Binary",
				"Common",
				.product(name: "TunnelModels", package: "tunnels-models"),
				.product(name: "WebSocketKit", package: "websocket-kit"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "TunnelClient",
			dependencies: [
				"Common",
				"WebSocket",
				.product(name: "TunnelModels", package: "tunnels-models"),
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "OAuth2Models", package: "swift-oauth2-models"),
				.product(name: "WebURL", package: "swift-url"),
				.product(name: "WebURLFoundationExtras", package: "swift-url"),
				.product(name: "WebSocketKit", package: "websocket-kit"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "TunnelServer",
			dependencies: [
				"ACME",
				"Common",
				"HTTPUpgradeServer",
				"WebSocket",
				.product(name: "TunnelModels", package: "tunnels-models"),
				.product(name: "AcmeSwift", package: "acmeswift"),
				.product(name: "EnvironmentVariables", package: "swift-environment-variables"),
				.product(name: "FzkExtensions", package: "swift-extensions"),
				.product(name: "OAuth2Models", package: "swift-oauth2-models"),
				.product(name: "WebURL", package: "swift-url"),
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "DebugServer",
			dependencies: [
				"CatchAll",
				"Common",
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		)
	] + executableTargets() + testTargets(),
	swiftLanguageModes: [.v6]
)

// MARK: Executable targets
func executableTargets() -> [Target] {
	[
		.executableTarget(
			name: "TunnelClientCLI",
			dependencies: [
				"TunnelClient",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "WebURL", package: "swift-url"),
			],
			swiftSettings: upcomingFeatures
		),
		.executableTarget(
			name: "TunnelServerCLI",
			dependencies: [
				"TunnelServer",
			],
			swiftSettings: upcomingFeatures
		),
		.executableTarget(
			name: "DNSServerCLI",
			dependencies: [
				"DNSServer",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			swiftSettings: upcomingFeatures
		),
		.executableTarget(
			name: "DebugServerCLI",
			dependencies: [
				"DebugServer",
			],
			swiftSettings: upcomingFeatures
		),
		.executableTarget(
			name: "LogReader",
			dependencies: [
				"TunnelClient",
				.product(name: "TunnelModels", package: "tunnels-models"),
				.product(name: "EnvironmentVariables", package: "swift-environment-variables"),
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
	]
}

// MARK: Test targets
func testTargets() -> [Target] {
	[
		.testTarget(
			name: "ACMETests",
			dependencies: [
				"ACME"
			],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "AppTests",
			dependencies: [
				"Common",
				"DebugServer",
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "XCTVapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "BinaryTests",
			dependencies: ["Binary"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "CommonTests",
			dependencies: [
				"Common",
			],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "DebugServerTests",
			dependencies: [
				"DebugServer",
				.product(name: "XCTVapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "DNSServerTests",
			dependencies: ["DNSServer"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "TunnelClientTests",
			dependencies: ["TunnelClient"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "TunnelServerTests",
			dependencies: [
				"TunnelServer",
				.product(name: "VaporTesting", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "WebSocketTests",
			dependencies: ["WebSocket"],
			swiftSettings: upcomingFeatures
		),
	]
}
