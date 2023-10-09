// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "tunnels",
	platforms: [ .macOS(.v13) ],
	products: [
		.executable(name: "dns-server", targets: ["DNSServer"]),
		.executable(name: "tunnels-client", targets: ["ClientCLI"]),
		.executable(name: "tunnels-server", targets: ["ServerCLI"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.59.0"),
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.84.1"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0"),
	],
	targets: [
		.target(name: "Binary"),
		.executableTarget(
			name: "DNSServer",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "NIO", package: "swift-nio"),
			]
		),
		.target(name: "Models"),
		.target(
			name: "TunnelsClient",
			dependencies: [
				"Models",
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "WebSocketKit", package: "websocket-kit"),
			]
		),
		.target(
			name: "TunnelsServer",
			dependencies: [
				"Models",
				.product(name: "Vapor", package: "vapor"),
			]
		),
		.executableTarget(name: "ClientCLI", dependencies: [
			"TunnelsClient",
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
		]),
		.executableTarget(name: "ServerCLI", dependencies: [ "TunnelsServer" ]),
		.testTarget(name: "BinaryTests", dependencies: ["Binary"]),
	]
)
