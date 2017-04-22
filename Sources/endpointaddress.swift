import Foundation
import Cast

public struct EndpointAddress
{
	public var host: String
	public var port: Int

	public init(host: String, port: Int)
	{
		self.host = host
		self.port = port
	}
}

internal extension EndpointAddress
{
	internal static func FromV4(_ addr: sockaddr_in) -> EndpointAddress
	{
		let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
		let saddr = UnsafeMutablePointer<in_addr>.allocate(capacity: 1)
		saddr.initialize(to: addr.sin_addr)

		_ = inet_ntop(
			Int32(addr.sin_family),
			Cast(saddr)!,
			Cast(addressBuffer),
			socklen_t(INET6_ADDRSTRLEN))

		let port = ntohs(addr.sin_port)
		let cstring: UnsafePointer<CChar> = Cast(addressBuffer)!

		return EndpointAddress(host: String(cString: cstring), port: Int(port))
	}

	internal static func FromV6(_ addr: sockaddr_in6) -> EndpointAddress
	{
		let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
		let saddr = UnsafeMutablePointer<in6_addr>.allocate(capacity: 1)
		saddr.initialize(to: addr.sin6_addr)

		_ = inet_ntop(
			Int32(addr.sin6_family),
			Cast(saddr)!,
			Cast(addressBuffer),
			socklen_t(INET6_ADDRSTRLEN))

		let port = ntohs(addr.sin6_port)
		let cstring: UnsafePointer<CChar> = Cast(addressBuffer)!

		return EndpointAddress(host: String(cString: cstring), port: Int(port))
	}
}

private func ntohs(_ value: CUnsignedShort) -> CUnsignedShort {
	return (value << 8) + (value >> 8);
}
