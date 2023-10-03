// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "tunnels-client",
	platforms: [ .macOS(.v10_15) ],
	products: [
		.executable(name: "tunnels", targets: ["CLI"])
	],
	dependencies: [
		.package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
	],
	targets: [
		.target(
			name: "Tunnels",
			dependencies: [
				.product(name: "AsyncHTTPClient", package: "async-http-client"),
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
