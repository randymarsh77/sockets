import Foundation

public enum ServerError: Error {
	case createSocketDescriptorError
	case bindingError
	case listenError
	case acceptConnectionError
}

public enum PortOption {
	case specific(UInt16)
	case range(UInt16, UInt16)
}

public struct ServerOptions {
	public init(port: PortOption) {
		self.port = port
	}

	let port: PortOption
}

public final class TCPServer: @unchecked Sendable {
	public let port: UInt16
	var running: Bool

	public init(options: ServerOptions, onConnection: @escaping @Sendable (Socket) -> Void) throws {
		self.running = true

		let sockFD = socket(AF_INET, SOCK_STREAM, 0)
		if sockFD == -1 {
			throw ServerError.createSocketDescriptorError
		}

		var sockOptOn = Int32(1)
		setsockopt(
			sockFD, SOL_SOCKET, SO_REUSEADDR, &sockOptOn,
			socklen_t(MemoryLayout.size(ofValue: sockOptOn)))

		var serverAddr = sockaddr_in()
		let serverAddrSize = socklen_t(MemoryLayout.size(ofValue: serverAddr))
		serverAddr.sin_len = UInt8(serverAddrSize)
		serverAddr.sin_family = sa_family_t(AF_INET)  // chooses IPv4

		var bindResult: Int32 = -1
		switch options.port {
		case .specific(let port):
			self.port = port
			serverAddr.sin_port = port.bigEndian
			bindResult = withUnsafePointer(to: &serverAddr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
					bind(sockFD, UnsafePointer(addr), serverAddrSize)
				}
			}
		case .range(let startPort, let endPort):
			var currentPort = startPort
			while bindResult < 0 && currentPort <= endPort {
				serverAddr.sin_port = currentPort.bigEndian
				bindResult = withUnsafePointer(to: &serverAddr) {
					$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
						bind(sockFD, UnsafePointer(addr), serverAddrSize)
					}
				}
				currentPort += 1
			}
			self.port = currentPort - 1
		}

		if bindResult == -1 {
			throw ServerError.bindingError
		}

		DispatchQueue.global(qos: .default).async {
			try? self.serve(sockFD, onConnection)
		}
	}

	public func dispose() {
		synced(lock: self) {
			self.running = false
		}
	}

	func serve(_ sockFD: Int32, _ onConnection: @escaping (Socket) -> Void) throws {
		var stillRunning = true
		while stillRunning && listen(sockFD, 5) != -1 {
			var clientAddr = sockaddr_storage()
			var clientAddrLen = socklen_t(MemoryLayout.size(ofValue: clientAddr))
			let clientFD = withUnsafeMutablePointer(to: &clientAddr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1) { addr in
					accept(sockFD, UnsafeMutablePointer(addr), &clientAddrLen)
				}
			}

			if clientFD == -1 {
				throw ServerError.acceptConnectionError
			}

			onConnection(
				Socket(
					fd: clientFD,
					address: SocketAddress.fromSockAddr(clientAddr).toEndpointAddress()))

			self.synced(lock: self) {
				stillRunning = self.running
			}
		}

		if stillRunning {
			throw ServerError.listenError
		}
	}

	func synced(lock: AnyObject, closure: () -> Void) {
		objc_sync_enter(lock)
		defer { objc_sync_exit(lock) }
		closure()
	}
}
