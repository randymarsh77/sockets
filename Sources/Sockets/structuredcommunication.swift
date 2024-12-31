import Foundation

@available(iOS 13.0.0, *)
@available(macOS 10.15.0, *)
public extension Socket {
	func getResponse<TRequest, TResponse>(data: TRequest) async -> TResponse {
		let dataBytes = UnsafeMutablePointer<TRequest>.allocate(capacity: 1)
		dataBytes.initialize(to: data)
		await self.write(Data(bytesNoCopy: dataBytes, count: MemoryLayout<TRequest>.size, deallocator: .free))

		let bytes = UInt32(MemoryLayout<TResponse>.size)
		let data = await self.read(bytes, minBytes: bytes)
		let value = data?.withUnsafeBytes {
			$0.baseAddress!.assumingMemoryBound(to: TResponse.self).pointee
		}
		return value!
	}

	func receiveAndRespond<T>(data: T) async -> T {
		let bytes = UInt32(MemoryLayout<T>.size)
		let request = await self.read(bytes, minBytes: bytes)
		let value = request?.withUnsafeBytes {
			$0.baseAddress!.assumingMemoryBound(to: T.self).pointee
		}

		let dataBytes = UnsafeMutablePointer<T>.allocate(capacity: 1)
		dataBytes.initialize(to: data)
		await self.write(Data(bytesNoCopy: dataBytes, count: MemoryLayout<T>.size, deallocator: .free))

		return value!
	}
}
