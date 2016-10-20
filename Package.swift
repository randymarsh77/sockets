import PackageDescription

let package = Package(
    name: "SynchronizedSockets",
    dependencies: [
		.Package(url: "https://www.github.com/krzyzanowskim/CryptoSwift", majorVersion: 0),
		.Package(url: "https://www.github.com/randymarsh77/cast", majorVersion: 1),
		.Package(url: "https://www.github.com/randymarsh77/idisposable", majorVersion: 1),
		.Package(url: "https://www.github.com/randymarsh77/scope", majorVersion: 1),
		.Package(url: "https://www.github.com/randymarsh77/time", majorVersion: 1),
	]
)
