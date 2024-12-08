import XCTest

@testable import Sockets

class SocketsTests: XCTestCase {
	func test() async {
		do {
			let message = "TEST"
			let messageData = message.data(using: .utf8)!
			let server = try TCPServer(options: ServerOptions(port: .range(10000, 20000))) {
				(socket) in
				socket.write(messageData)
			}
			let port = await Int(server.port)
			let client = TCPClient(endpoint: EndpointAddress(host: "localhost", port: port))
			let socket = try client.tryConnect()
			let response = socket.read(
				UInt32(messageData.count), minBytes: UInt32(messageData.count))

			socket.dispose()
			await server.dispose()

			XCTAssertEqual(String(data: response!, encoding: .utf8), message)
		} catch {
			XCTAssert(false, "Unexpected error: \(error).")
		}
	}
}
