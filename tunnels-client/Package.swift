// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "tunnels-client",
	products: [
		.executable(name: "tunnels", targets: ["CLI"])
	],
	targets: [
		.target(
			name: "Tunnels"
		),
		.executableTarget(
			name: "CLI",
			dependencies: [
				"Tunnels",
			]
		),
	]
)
