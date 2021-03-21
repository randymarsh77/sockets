// swift-tools-version:5.1
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
		),
	],
	dependencies: [
		.package(url: "https://github.com/krzyzanowskim/CryptoSwift", .exact("1.3.1")),
		.package(url: "https://github.com/randymarsh77/cast", .branch("master")),
		.package(url: "https://github.com/randymarsh77/idisposable", .branch("master")),
		.package(url: "https://github.com/randymarsh77/scope", .branch("master")),
		.package(url: "https://github.com/randymarsh77/time", .branch("master")),
		.package(url: "https://github.com/Bouke/NetService", .branch("master")),
	],
	targets: [
		.target(
			name: "Sockets",
			dependencies: dependencies.map { Target.Dependency(stringLiteral: $0) }
		),
	]
)
