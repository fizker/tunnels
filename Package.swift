// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "tunnels",
	platforms: [ .macOS(.v13) ],
	products: [
		.executable(name: "tunnels-client", targets: ["ClientCLI"]),
		.executable(name: "tunnels-server", targets: ["ServerCLI"]),
	],
	dependencies: [
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.84.1"),
		.package(url: "https://github.com/vapor/websocket-kit.git", from: "2.14.0"),
	],
	targets: [
		.target(
			name: "TunnelsClient",
			dependencies: [
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
				.product(name: "WebSocketKit", package: "websocket-kit"),
			]
		),
		.target(
			name: "TunnelsServer",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
			]
		),
		.executableTarget(name: "ClientCLI", dependencies: [ "TunnelsClient" ]),
		.executableTarget(name: "ServerCLI", dependencies: [ "TunnelsServer" ]),
	]
)
