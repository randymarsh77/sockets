import Foundation

public enum TCPClientError: Error {
	case SocketError(code: Int32, message: String)
	case FailedToConnect(message: String)
}

public class TCPClient {
	var endpoint: EndpointAddress

	public init(endpoint: EndpointAddress) {
		self.endpoint = endpoint
	}

	public func dispose() {
		// TODO: Probably something here
	}

	public func tryConnect() throws -> Socket? {
		var sockfd: Int32 = -1
		var hints = addrinfo(
			ai_flags: 0,
			ai_family: AF_UNSPEC,
			ai_socktype: SOCK_STREAM,
			ai_protocol: IPPROTO_TCP,
			ai_addrlen: 0,
			ai_canonname: nil,
			ai_addr: nil,
			ai_next: nil)

		var result: UnsafeMutablePointer<addrinfo>?

		let error = getaddrinfo(endpoint.host, "\(endpoint.port)", &hints, &result)
		if error != 0 { throw TCPClientError.SocketError(code: error, message: "getaddrinfo") }

		var p = result
		while p != nil {
			let current = p!.pointee

			sockfd = socket(current.ai_family, current.ai_socktype, current.ai_protocol)
			if sockfd == -1 {
				perror("client: socket")
				p = current.ai_next
				continue
			}

			let connectResult = connect(sockfd, current.ai_addr, current.ai_addrlen)
			if connectResult == -1 {
				close(sockfd)
				perror("client: connect")
				p = current.ai_next
				continue
			}

			break
		}

		if p == nil { throw TCPClientError.FailedToConnect(message: "All sockets failed") }

		return Socket(fd: sockfd, address: endpoint)
	}
}
