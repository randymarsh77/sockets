// Synchronized Network Stream
// A partial protocol that sends timestamp tokens

import Foundation
import Time

public enum SNSError: Error {
	case invalidHeader
}

public let SNSHeaderLength =
	MemoryLayout<UInt16>.size + MemoryLayout<Double>.size + MemoryLayout<Double>.size

public class SNSUtility {
	public static func generateHeader(synchronization: TimeSynchronization) -> Data {
		let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: SNSHeaderLength)
		memcpy(bytes, toByteArray(value: UInt16(0xFEED)), MemoryLayout<UInt16>.size)
		memcpy(
			bytes.advanced(by: MemoryLayout<UInt16>.size),
			toByteArray(value: synchronization.syncTime.convert(to: .seconds).value),
			MemoryLayout<Double>.size)
		memcpy(
			bytes.advanced(by: MemoryLayout<UInt16>.size + MemoryLayout<Double>.size),
			toByteArray(value: synchronization.receiveGuess.convert(to: .seconds).value),
			MemoryLayout<Double>.size)

		return Data(bytesNoCopy: bytes, count: SNSHeaderLength, deallocator: .free)
	}

	public static func isValidHeader(chunk: Data) -> Bool {
		return chunk.count >= SNSHeaderLength
			&& chunk.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Bool in
				bytes.load(fromByteOffset: 0, as: UInt16.self) == 0xFEED
			}
	}

	public static func parseHeader(chunk: Data) throws -> TimeSynchronization {
		if chunk.count < SNSHeaderLength { throw SNSError.invalidHeader }
		if !isValidHeader(chunk: chunk) { throw SNSError.invalidHeader }

		let start = UnsafeMutablePointer<Double>.allocate(capacity: 1)
		let guess = UnsafeMutablePointer<Double>.allocate(capacity: 1)
		defer {
			start.deinitialize(count: 1)
			start.deallocate()
			guess.deinitialize(count: 1)
			guess.deallocate()
		}

		return chunk.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
			memcpy(
				start, raw.baseAddress!.advanced(by: MemoryLayout<UInt16>.size),
				MemoryLayout<Double>.size)
			memcpy(
				guess,
				raw.baseAddress!
					.advanced(
						by: MemoryLayout<UInt16>.size + MemoryLayout<Double>.size),
				MemoryLayout<Double>.size)

			return TimeSynchronization(
				syncTime: Time.fromInterval(start.pointee, unit: .seconds),
				receiveGuess: Time.fromInterval(guess.pointee, unit: .seconds))
		}
	}
}

func toByteArray<T>(value: T) -> [UInt8] {
	var value = value
	return withUnsafePointer(to: &value) {
		$0.withMemoryRebound(to: UInt8.self, capacity: 1) { byte in
			Array(
				UnsafeBufferPointer(start: UnsafePointer<UInt8>(byte), count: MemoryLayout<T>.size))
		}
	}
}
