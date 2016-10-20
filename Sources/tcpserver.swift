import Foundation

public class TCPServer
{
	var running: Bool

	public init(port: UInt16, onConnection: @escaping (Socket) -> Void)
	{
		self.running = true
		
		let sock_fd = socket(AF_INET, SOCK_STREAM, 0)
		if sock_fd == -1 {
			perror("Failure: creating socket")
			exit(EXIT_FAILURE)
		}

		var sock_opt_on = Int32(1)
		setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR, &sock_opt_on, socklen_t(MemoryLayout.size(ofValue: sock_opt_on)))

		var server_addr = sockaddr_in()
		let server_addr_size = socklen_t(MemoryLayout.size(ofValue: server_addr))
		server_addr.sin_len = UInt8(server_addr_size)
		server_addr.sin_family = sa_family_t(AF_INET) // chooses IPv4
		server_addr.sin_port = port.bigEndian // chooses the port

		let bind_server = withUnsafePointer(to: &server_addr) {
			$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
				bind(sock_fd, UnsafePointer(addr), server_addr_size)
			}
		}
		if bind_server == -1 {
			perror("Failure: binding port")
			exit(EXIT_FAILURE)
		}

		DispatchQueue.global(qos: .default).async
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
					perror("Failure: accepting connection")
					exit(EXIT_FAILURE);
				}

				onConnection(Socket(fd: client_fd))

				self.synced(lock: self) {
					stillRunning = self.running
				}
			}

			if !stillRunning
			{
				perror("Failure: listening")
				exit(EXIT_FAILURE)
			}
		}
	}

	public func dispose() -> Void
	{
		synced(lock: self) {
			self.running = false
		}
	}

	func synced(lock: AnyObject, closure: () -> ())
	{
		objc_sync_enter(lock)
		defer { objc_sync_exit(lock) }
		closure()
	}
}
