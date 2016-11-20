import PackageDescription

let package = Package(
    name: "Sockets",
    dependencies: [
		.Package(url: "https://github.com/krzyzanowskim/CryptoSwift", majorVersion: 0),
		.Package(url: "https://github.com/randymarsh77/cast", majorVersion: 1),
		.Package(url: "https://github.com/randymarsh77/idisposable", majorVersion: 1),
		.Package(url: "https://github.com/randymarsh77/scope", majorVersion: 1),
		.Package(url: "https://github.com/randymarsh77/time", majorVersion: 1),
	]
)
