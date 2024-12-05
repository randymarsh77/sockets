// swift-tools-version:6.0
import PackageDescription

var dependencies = [
	"CryptoSwift",
	"Cast",
	"IDisposable",
	"Scope",
	"Time",
]

#if os(Linux)
	dependencies.append("NetService")
#endif

let package = Package(
	name: "Sockets",
	products: [
		.library(
			name: "Sockets",
			targets: ["Sockets"]
		)
	],
	dependencies: [
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift", exact: "1.8.1"),
		.package(url: "https://github.com/randymarsh77/cast", branch: "master"),
		.package(url: "https://github.com/randymarsh77/idisposable", branch: "master"),
		.package(url: "https://github.com/randymarsh77/scope", branch: "master"),
		.package(url: "https://github.com/randymarsh77/time", branch: "master"),
		.package(url: "https://github.com/Bouke/NetService", branch: "master"),
	],
	targets: [
		.target(
			name: "Sockets",
			dependencies: dependencies.map { .product(name: $0, package: $0) }
		),
		.testTarget(name: "SocketsTests", dependencies: ["Sockets"]),
	]
)
