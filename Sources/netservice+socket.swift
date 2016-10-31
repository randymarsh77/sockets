import Foundation
import Cast

public extension NetService {

	func getEndpointAddress() -> EndpointAddress?
	{
		if (self.addresses == nil || self.addresses!.count == 0) {
			return nil
		}

		for data in self.addresses!
		{
			let socketAddress = GetSocketAddress(data)
			switch socketAddress
			{
			case let .IPV4(addr):
				return EPAddressFromV4(addr)
			case let .IPV6(addr):
				return EPAddressFromV6(addr)
			default:
				continue
			}
		}

		return nil
	}
}

private enum SocketAddress {
	case IPV4(sockaddr_in)
	case IPV6(sockaddr_in6)
	case Unknown
}

private func GetSocketAddress(_ data: Data) -> SocketAddress
{
	switch data.count
	{
	case MemoryLayout<sockaddr_in>.size:
		return .IPV4(data.CastCopiedBytes())
	case MemoryLayout<sockaddr_in6>.size:
		return .IPV6(data.CastCopiedBytes())
	default:
		return .Unknown
	}
}

private func EPAddressFromV4(_ addr: sockaddr_in) -> EndpointAddress
{
	let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
	let saddr = UnsafeMutablePointer<in_addr>.allocate(capacity: 1)
	saddr.initialize(to: addr.sin_addr)

	_ = inet_ntop(
		Int32(addr.sin_family),
		Cast(saddr)!,
		Cast(addressBuffer),
		socklen_t(INET6_ADDRSTRLEN))

	let port = addr.sin_port

	return EndpointAddress(host: String(describing: addressBuffer), port: Int(port))
}

private func EPAddressFromV6(_ addr: sockaddr_in6) -> EndpointAddress
{
	let addressBuffer = malloc(Int(INET6_ADDRSTRLEN))
	let saddr = UnsafeMutablePointer<in6_addr>.allocate(capacity: 1)
	saddr.initialize(to: addr.sin6_addr)

	_ = inet_ntop(
		Int32(addr.sin6_family),
		Cast(saddr)!,
		Cast(addressBuffer),
		socklen_t(INET6_ADDRSTRLEN))

	let port = addr.sin6_port

	return EndpointAddress(host: String(describing: addressBuffer), port: Int(port))
}
