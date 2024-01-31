// swift-tools-version: 5.9

import PackageDescription

let upcomingFeatures: [SwiftSetting] = [
	.enableUpcomingFeature("ConciseMagicFile"),
	.enableUpcomingFeature("ForwardTrailingClosures"),
	.enableUpcomingFeature("ExistentialAny"),
	.enableUpcomingFeature("StrictConcurrency"),
	.enableUpcomingFeature("ImplicitOpenExistentials"),
	.enableUpcomingFeature("BareSlashRegexLiterals"),
]

let package = Package(
	name: "tunnels",
	platforms: [ .macOS(.v13) ],
	products: [
		.executable(name: "dns-server", targets: ["DNSServerCLI"]),
		.executable(name: "tunnel-client", targets: ["ClientCLI"]),
		.executable(name: "tunnel-server", targets: ["ServerCLI"]),
		.executable(name: "tunnel-logs", targets: ["LogReader"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
		.package(url: "https://github.com/fizker/swift-environment-variables.git", from: "1.0.0"),
		.package(url: "https://github.com/fizker/swift-oauth2-models.git", .upToNextMinor(from: "0.3.0")),
		.package(url: "https://github.com/m-barthelemy/AcmeSwift.git", from: "1.0.0-beta3"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.20.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.90.0"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0"),
	],
	targets: [
		.target(
			name: "Binary",
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
		.executableTarget(
			name: "ClientCLI",
			dependencies: [
				"TunnelClient",
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			],
			swiftSettings: upcomingFeatures
		),
		.executableTarget(
			name: "ServerCLI",
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
			name: "LogReader",
			dependencies: [
				"Models",
				"TunnelClient",
				.product(name: "EnvironmentVariables", package: "swift-environment-variables"),
				.product(name: "Vapor", package: "vapor"),
			],
			swiftSettings: upcomingFeatures),
		.testTarget(
			name: "BinaryTests",
			dependencies: ["Binary"],
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
)
