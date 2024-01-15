import Foundation
import Cast

internal enum SocketAddress {
	case IPV4(sockaddr_in)
	case IPV6(sockaddr_in6)
	case Unknown
}

internal extension SocketAddress {
	static func FromSockAddr(_ addr: sockaddr_storage) -> SocketAddress {
		switch addr.ss_len {
		case UInt8(MemoryLayout<sockaddr_in>.size):
			return .IPV4(sto4(addr))
		case UInt8(MemoryLayout<sockaddr_in6>.size):
			return .IPV6(sto6(addr))
		default:
			return .Unknown
		}
	}

	static func FromData(_ data: Data) -> SocketAddress {
		switch data.count {
		case MemoryLayout<sockaddr_in>.size:
			return .IPV4(data.CastCopiedBytes())
		case MemoryLayout<sockaddr_in6>.size:
			return .IPV6(data.CastCopiedBytes())
		default:
			return .Unknown
		}
	}
}

internal extension SocketAddress {
	func toEndpointAddress() -> EndpointAddress {
		switch self {
		case let .IPV4(addr):
			return EndpointAddress.FromV4(addr)
		case let .IPV6(addr):
			return EndpointAddress.FromV6(addr)
		default:
			return EndpointAddress(host: "0", port: 0)
		}
	}
}

func sto4(_ addr: sockaddr_storage) -> sockaddr_in {
	var paddr = UnsafeMutablePointer<sockaddr_storage>.allocate(capacity: 1)
	let presult = UnsafeMutablePointer<sockaddr_in>.allocate(capacity: 1)
	paddr.initialize(to: addr)

	withUnsafePointer(to: &paddr) { presult.initialize(to: Cast($0).pointee) }

	return presult.pointee
}

func sto6(_ addr: sockaddr_storage) -> sockaddr_in6 {
	var paddr = UnsafeMutablePointer<sockaddr_storage>.allocate(capacity: 1)
	let presult = UnsafeMutablePointer<sockaddr_in6>.allocate(capacity: 1)
	paddr.initialize(to: addr)

	withUnsafePointer(to: &paddr) { presult.initialize(to: Cast($0).pointee) }

	return presult.pointee
}
