import Foundation
import Socks

public class StructuredCommunicationSeed
{
	var socket: Socket

	public init(socket: Socket)
	{
		self.socket = socket
	}

	public func send<T>(data: T) -> StructuredCommunicationSeed
	{
		let dataBytes = UnsafeMutablePointer<T>.allocate(capacity: 1)
		dataBytes.initialize(to: data)
		socket.write(Data(bytesNoCopy: dataBytes, count: MemoryLayout<T>.size, deallocator: .free))
		return self
	}

	public func recieve<T>() -> StructuredCommunication<T>
	{
		let bytes = UInt32(MemoryLayout<T>.size)
		let data = socket.read(bytes, minBytes: bytes)
		let value = data?.withUnsafeBytes() { (bytes: UnsafePointer<T>) -> T in
			bytes.pointee
		}
		return StructuredCommunication<T>(socket: socket, value: value!)
	}
}

public class StructuredCommunication<T> : StructuredCommunicationSeed
{
	var accumulator: T

	public init(socket: Socket, value: T)
	{
		self.accumulator = value
		super.init(socket: socket)
	}

	public func send<U>(data: U) -> StructuredCommunication<T>
	{
		_ = super.send(data: data)
		return self
	}

	public func communicate() -> T
	{
		return self.accumulator
	}
}
