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

@available(macOS 10.15.0, *)
public final actor TCPServer: @unchecked Sendable {
	public let port: UInt16

	private var running: Bool

	public init(options: ServerOptions, onConnection: @escaping @Sendable (Socket) async -> Void) throws {
		running = true

		#if os(Linux)
			let domain = Int32(2)  // AF_INET
			let type = Int32(1)  // SOCK_STREAM
		#else
			let domain = AF_INET
			let type = SOCK_STREAM
		#endif

		let sockFD = socket(domain, type, 0)
		if sockFD == -1 {
			throw ServerError.createSocketDescriptorError
		}

		var sockOptOn = Int32(1)
		setsockopt(
			sockFD, SOL_SOCKET, SO_REUSEADDR, &sockOptOn,
			socklen_t(MemoryLayout.size(ofValue: sockOptOn)))

		var serverAddr = sockaddr_in()
		let serverAddrSize = socklen_t(MemoryLayout.size(ofValue: serverAddr))
		#if !os(Linux)
			serverAddr.sin_len = UInt8(serverAddrSize)
		#endif
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
			Task {
				try? await self.serve(sockFD, onConnection)
			}
		}
	}

	public func dispose() {
		running = false

		let client = TCPClient(endpoint: EndpointAddress(host: "localhost", port: Int(port)))
		let socket = try? client.tryConnect()
		socket?.dispose()
	}

	func serve(_ sockFD: Int32, _ onConnection: @escaping (Socket) async -> Void) async throws {
		while running && listen(sockFD, 5) != -1 {
			var clientAddr = sockaddr_storage()
			let clientAddrLen = socklen_t(MemoryLayout.size(ofValue: clientAddr))
			let addressPtr = withUnsafeMutablePointer(to: &clientAddr) {
				$0.withMemoryRebound(to: sockaddr.self, capacity: 1){ addr in
					UnsafeMutablePointer(addr)
				}
			}
			let clientFDTask =
				Task {
					var clientAddrLenRef = clientAddrLen
					return accept(sockFD, addressPtr, &clientAddrLenRef)
				}

			let clientFDResult = await clientFDTask.result
			let clientFD = clientFDResult.get()

			if clientFD == -1 {
				throw ServerError.acceptConnectionError
			}

			let socket = Socket(
				fd: clientFD,
				address: SocketAddress.fromSockAddr(clientAddr).toEndpointAddress())

			if running {
				await onConnection(socket)
			} else {
				socket.dispose()
			}
		}

		if running {
			throw ServerError.listenError
		}
	}
}
