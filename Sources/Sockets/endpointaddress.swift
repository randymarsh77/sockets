import Cast
import Foundation

public struct EndpointAddress: Sendable {
	public let host: String
	public let port: Int

	public init(host: String, port: Int) {
		self.host = host
		self.port = port
	}
}

extension EndpointAddress {
	static func fromV4(_ addr: sockaddr_in) -> EndpointAddress {
		let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
		let saddr = UnsafeMutablePointer<in_addr>.allocate(capacity: 1)
		saddr.initialize(to: addr.sin_addr)

		_ = inet_ntop(
			Int32(addr.sin_family),
			cast(saddr)!,
			cast(addressBuffer),
			socklen_t(INET6_ADDRSTRLEN))

		let port = ntohs(addr.sin_port)
		let cstring: UnsafePointer<CChar> = cast(addressBuffer)!

		return EndpointAddress(host: String(cString: cstring), port: Int(port))
	}

	static func fromV6(_ addr: sockaddr_in6) -> EndpointAddress {
		let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
		let saddr = UnsafeMutablePointer<in6_addr>.allocate(capacity: 1)
		saddr.initialize(to: addr.sin6_addr)

		_ = inet_ntop(
			Int32(addr.sin6_family),
			cast(saddr)!,
			cast(addressBuffer),
			socklen_t(INET6_ADDRSTRLEN))

		let port = ntohs(addr.sin6_port)
		let cstring: UnsafePointer<CChar> = cast(addressBuffer)!

		return EndpointAddress(host: String(cString: cstring), port: Int(port))
	}
}

private func ntohs(_ value: CUnsignedShort) -> CUnsignedShort {
	return (value << 8) + (value >> 8)
}
