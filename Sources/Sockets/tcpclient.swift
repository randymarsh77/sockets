import Foundation

public enum TCPClientError: Error {
	case socketError(code: Int32, message: String)
	case failedToConnect(message: String)
}

public class TCPClient {
	let endpoint: EndpointAddress

	public init(endpoint: EndpointAddress) {
		self.endpoint = endpoint
	}

	public func tryConnect() throws -> Socket {
		var sockFD: Int32 = -1
		#if os(Linux)
			var hints = addrinfo(
				ai_flags: 0,
				ai_family: AF_UNSPEC,
				ai_socktype: Int32(1),  // SOCK_STREAM
				ai_protocol: Int32(IPPROTO_TCP),
				ai_addrlen: 0,
				ai_addr: nil,
				ai_canonname: nil,
				ai_next: nil)
		#else
			var hints = addrinfo(
				ai_flags: 0,
				ai_family: AF_UNSPEC,
				ai_socktype: SOCK_STREAM,
				ai_protocol: IPPROTO_TCP,
				ai_addrlen: 0,
				ai_canonname: nil,
				ai_addr: nil,
				ai_next: nil)
		#endif

		var result: UnsafeMutablePointer<addrinfo>?

		let error = getaddrinfo(endpoint.host, "\(endpoint.port)", &hints, &result)
		if error != 0 { throw TCPClientError.socketError(code: error, message: "getaddrinfo") }

		var ptr = result
		while ptr != nil {
			let current = ptr!.pointee

			sockFD = socket(current.ai_family, current.ai_socktype, current.ai_protocol)
			if sockFD == -1 {
				perror("client: socket")
				ptr = current.ai_next
				continue
			}

			let connectResult = connect(sockFD, current.ai_addr, current.ai_addrlen)
			if connectResult == -1 {
				close(sockFD)
				perror("client: connect")
				ptr = current.ai_next
				continue
			}

			break
		}

		if ptr == nil { throw TCPClientError.failedToConnect(message: "All sockets failed") }

		return Socket(fd: sockFD, address: endpoint)
	}
}
