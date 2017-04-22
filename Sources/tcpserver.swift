import Foundation

public enum ServerError : Error
{
	case CreateSocketDescriptorError
	case BindingError
	case ListenError
	case AcceptConnectionError
}

public enum PortOption
{
	case Specific(UInt16)
	case Range(UInt16, UInt16)
}

public struct ServerOptions
{
	public init(port: PortOption) {
		self.port = port
	}

	let port: PortOption
}

public class TCPServer
{
	public let port: UInt16
	var running: Bool

	public init(options: ServerOptions, onConnection: @escaping (Socket) -> Void) throws
	{
		self.running = true
		
		let sock_fd = socket(AF_INET, SOCK_STREAM, 0)
		if sock_fd == -1 {
			throw ServerError.CreateSocketDescriptorError
		}

		var sock_opt_on = Int32(1)
		setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

		var server_addr = sockaddr_in()
		let server_addr_size = socklen_t(MemoryLayout.size(ofValue: server_addr))
		server_addr.sin_len = UInt8(server_addr_size)
		server_addr.sin_family = sa_family_t(AF_INET) // chooses IPv4

		var bindResult: Int32 = -1
		switch (options.port)
		{
		case .Specific(let port):
			self.port = port
			server_addr.sin_port = port.bigEndian
			bindResult = withUnsafePointer(to: &server_addr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
					bind(sock_fd, UnsafePointer(addr), server_addr_size)
				}
			}
			break
		case .Range(let startPort, let endPort):
			var currentPort = startPort
			while (bindResult < 0 && currentPort <= endPort) {
				server_addr.sin_port = currentPort.bigEndian
				bindResult = withUnsafePointer(to: &server_addr) {
					$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
						bind(sock_fd, UnsafePointer(addr), server_addr_size)
					}
				}
				currentPort += 1
			}
			self.port = currentPort - 1
			break
		}

		if bindResult == -1 {
			throw ServerError.BindingError
		}

		DispatchQueue.global(qos: .default).async
		{
			try! self.serve(sock_fd, onConnection)
		}
	}

	public func dispose() -> Void
	{
		synced(lock: self) {
			self.running = false
		}
	}

	func serve(_ sock_fd: Int32, _ onConnection: @escaping (Socket) -> Void) throws
	{
		var stillRunning = true
		while stillRunning && listen(sock_fd, 5) != -1
		{
			var client_addr = sockaddr_storage()
			var client_addr_len = socklen_t(MemoryLayout.size(ofValue: client_addr))
			let client_fd = withUnsafeMutablePointer(to: &client_addr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
					accept(sock_fd, UnsafeMutablePointer(addr), &client_addr_len)
				}
			}

			if client_fd == -1 {
				throw ServerError.AcceptConnectionError
			}

			onConnection(Socket(fd: client_fd, address: SocketAddress.FromSockAddr(client_addr).toEndpointAddress()))

			self.synced(lock: self) {
				stillRunning = self.running
			}
		}

		if stillRunning
		{
			throw ServerError.ListenError
		}
	}

	func synced(lock: AnyObject, closure: () -> ())
	{
		objc_sync_enter(lock)
		defer { objc_sync_exit(lock) }
		closure()
	}
}
