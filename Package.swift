// swift-tools-version:5.3

import PackageDescription

let package = Package(
	name: "Protoquest",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
	],
	products: [
		.library(
			name: "Protoquest",
			targets: ["Protoquest"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/juliand665/HandyOperators", from: "2.0.0"),
		.package(url: "https://github.com/juliand665/ArrayBuilder", .branch("main"))
	],
	targets: [
		.target(
			name: "Protoquest",
			dependencies: [
				"HandyOperators",
				"ArrayBuilder",
			]
		),
		.testTarget(
			name: "ProtoquestTests",
			dependencies: ["Protoquest"]
		),
	]
)
