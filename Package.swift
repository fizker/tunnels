// swift-tools-version: 5.10

import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
	.enableUpcomingFeature("ConciseMagicFile"),
	.enableUpcomingFeature("ForwardTrailingClosures"),
	.enableUpcomingFeature("ExistentialAny"),
	.enableExperimentalFeature("StrictConcurrency"),
	.enableUpcomingFeature("ImplicitOpenExistentials"),
	.enableUpcomingFeature("BareSlashRegexLiterals"),
	.enableUpcomingFeature("GlobalConcurrency"),
	.enableUpcomingFeature("IsolatedDefaultValues"),
	.enableUpcomingFeature("DisableOutwardActorInference"),
	.enableUpcomingFeature("DeprecateApplicationMain"),
//	.enableUpcomingFeature("InternalImportsByDefault"),
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
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
		.package(url: "https://github.com/apple/swift-asn1.git", from: "1.1.0"),
		.package(url: "https://github.com/apple/swift-certificates.git", from: "1.4.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", from: "3.4.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.66.0"),
		.package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.27.0"),
		.package(url: "https://github.com/fizker/swift-environment-variables.git", from: "1.0.1"),
		.package(url: "https://github.com/fizker/swift-extensions.git", from:"1.3.0"),
		.package(url: "https://github.com/fizker/swift-oauth2-models.git", .upToNextMinor(from: "0.4.0")),
		.package(url: "https://github.com/karwa/swift-url", .upToNextMinor(from: "0.4.2")),
		.package(url: "https://github.com/m-barthelemy/AcmeSwift.git", from: "1.0.0-beta4"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.1"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.101.2"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.15.0"),
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
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
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
			name: "Models",
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "WebSocket",
			dependencies: [
				"Binary",
				"Common",
				"Models",
				.product(name: "WebSocketKit", package: "websocket-kit"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "TunnelClient",
			dependencies: [
				"Common",
				"Models",
				"WebSocket",
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
				"Models",
				"WebSocket",
				.product(name: "AcmeSwift", package: "acmeswift"),
				.product(name: "EnvironmentVariables", package: "swift-environment-variables"),
				.product(name: "OAuth2Models", package: "swift-oauth2-models"),
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "DebugServer",
			dependencies: [
				"CatchAll",
				"Common",
				.product(name: "EnvironmentVariables", package: "swift-environment-variables"),
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures
		)
	] + executableTargets() + testTargets()
)

// MARK: Executable targets
func executableTargets() -> [Target] {
	[
		.executableTarget(
			name: "ACMEDataConverter",
			dependencies: [
				"ACME",
				"Common",
				.product(name: "AcmeSwift", package: "acmeswift"),
				.product(name: "SwiftASN1", package: "swift-asn1"),
				.product(name: "X509", package: "swift-certificates"),
				.product(name: "NIOSSL", package: "swift-nio-ssl"),
			],
			swiftSettings: upcomingFeatures
		),
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
				"Models",
				"TunnelClient",
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
			name: "ModelsTests",
			dependencies: ["Models"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "TunnelClientTests",
			dependencies: ["TunnelClient"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "TunnelServerTests",
			dependencies: ["TunnelServer"],
			swiftSettings: upcomingFeatures
		),
		.testTarget(
			name: "WebSocketTests",
			dependencies: ["WebSocket"],
			swiftSettings: upcomingFeatures
		),
	]
}
