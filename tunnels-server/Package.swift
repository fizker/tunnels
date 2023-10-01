// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "tunnels-server",
	platforms: [ .macOS(.v10_15) ],
	dependencies: [
		.package(url: "https://github.com/vapor/vapor.git", from: "4.84.1"),
	],
	targets: [
		.executableTarget(name: "Run", dependencies: [ "App" ]),
		.target(
			name: "App",
			dependencies: [
				.product(name: "Vapor", package: "vapor"),
			]
		),
	]
)
