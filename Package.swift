// swift-tools-version:5.1
import PackageDescription

let package = Package(
	name: "Sockets",
	products: [
		.library(
			name: "Sockets",
			targets: ["Sockets"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift", .exact("1.3.1")),
		.package(url: "https://github.com/randymarsh77/cast", .branch("master")),
		.package(url: "https://github.com/randymarsh77/idisposable", .branch("master")),
		.package(url: "https://github.com/randymarsh77/scope", .branch("master")),
		.package(url: "https://github.com/randymarsh77/time", .branch("master")),
	],
	targets: [
		.target(
			name: "Sockets",
			dependencies: [
				"CryptoSwift",
				"Cast",
				"IDisposable",
				"Scope",
				"Time",
			]
		),
	]
)
