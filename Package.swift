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
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
		.package(url: "https://github.com/apple/swift-crypto.git", from: "3.4.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.66.0"),
		.package(url: "https://github.com/fizker/swift-environment-variables.git", from: "1.0.1"),
		.package(url: "https://github.com/fizker/swift-oauth2-models.git", .upToNextMinor(from: "0.4.0")),
		.package(url: "https://github.com/m-barthelemy/AcmeSwift.git", from: "1.0.0-beta4"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.1"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.101.2"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.15.0"),
	],
	targets: [
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
				.product(name: "WebSocketKit", package: "websocket-kit"),
			],
			swiftSettings: upcomingFeatures
		),
		.target(
			name: "TunnelServer",
			dependencies: [
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

func executableTargets() -> [Target] {
	[
		.executableTarget(
			name: "TunnelClientCLI",
			dependencies: [
				"TunnelClient",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
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

func testTargets() -> [Target] {
	[
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
