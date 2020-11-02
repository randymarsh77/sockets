// Synchronized Network Stream
// A partial protocol that sends timestamp tokens

import Foundation
import Time

public enum SNSError : Error
{
	case InvalidHeader
}

public let SNSHeaderLength = MemoryLayout<UInt16>.size + MemoryLayout<Double>.size + MemoryLayout<Double>.size

public class SNSUtility
{
	public static func GenerateHeader(synchronization: TimeSynchronization) -> Data
	{
		let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: SNSHeaderLength)
		memcpy(bytes, UnsafeRawPointer(toByteArray(value: UInt16(0xFEED))), MemoryLayout<UInt16>.size)
		memcpy(bytes.advanced(by: MemoryLayout<UInt16>.size), UnsafeRawPointer(toByteArray(value: synchronization.syncTime.convert(to: .Seconds).value)), MemoryLayout<Double>.size)
		memcpy(bytes.advanced(by: MemoryLayout<UInt16>.size + MemoryLayout<Double>.size), UnsafeRawPointer(toByteArray(value: synchronization.recieveGuess.convert(to: .Seconds).value)), MemoryLayout<Double>.size)

		return Data(bytesNoCopy: bytes, count: SNSHeaderLength, deallocator: .free)
	}

	public static func IsValidHeader(chunk: Data) -> Bool
	{
		return chunk.count >= SNSHeaderLength && chunk.withUnsafeBytes() { (bytes: UnsafeRawBufferPointer) -> Bool in
			bytes.load(fromByteOffset: 0, as: UInt16.self) == 0xFEED
		}
	}

	public static func ParseHeader(chunk: Data) throws -> TimeSynchronization
	{
		if chunk.count < SNSHeaderLength { throw SNSError.InvalidHeader }
		if !IsValidHeader(chunk: chunk) { throw SNSError.InvalidHeader }

		let start = UnsafeMutablePointer<Double>.allocate(capacity: 1)
		let guess = UnsafeMutablePointer<Double>.allocate(capacity: 1)
		defer {
			start.deinitialize(count: 1)
			start.deallocate()
			guess.deinitialize(count: 1)
			guess.deallocate()
		}

		return chunk.withUnsafeBytes() { (bytes: UnsafePointer<UInt8>) -> TimeSynchronization in

			memcpy(start, bytes.advanced(by: MemoryLayout<UInt16>.size), MemoryLayout<Double>.size)
			memcpy(guess, bytes.advanced(by: MemoryLayout<UInt16>.size + MemoryLayout<Double>.size), MemoryLayout<Double>.size)

			return TimeSynchronization(syncTime: Time.FromInterval(start.pointee, unit: .Seconds), recieveGuess: Time.FromInterval(guess.pointee, unit: .Seconds))
		}
	}
}

func toByteArray<T>(value: T) -> [UInt8] {
	var value = value
	return withUnsafePointer(to: &value) {
		$0.withMemoryRebound(to: UInt8.self, capacity: 1) { b in
			Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(b), count: MemoryLayout<T>.size))
		}
	}
}
