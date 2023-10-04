// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "tunnels-client",
	platforms: [ .macOS(.v13) ],
	products: [
		.executable(name: "tunnels", targets: ["CLI"])
	],
	dependencies: [
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0"),

	],
	targets: [
		.target(
			name: "Tunnels",
			dependencies: [
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "WebSocketKit", package: "websocket-kit"),
			]
		),
		.executableTarget(
			name: "CLI",
			dependencies: [
				"Tunnels",
			]
		),
	]
)
