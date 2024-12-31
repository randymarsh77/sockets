import Foundation
import Time

public struct NetworkLatency: Sendable {
	public let differenceOnReceive: Time
	public let roundTrip: Time
}

@available(iOS 13.0.0, *)
@available(macOS 10.15.0, *)
extension Socket {
	public func ping() async -> NetworkLatency {
		let start = Time.now
		let client = Time.fromSystemTimeStamp(await self.getResponse(data: Time.now))
		let end = Time.now
		return NetworkLatency(differenceOnReceive: client - start, roundTrip: end - start)
	}

	public func pong() async {
		let _ = await self.receiveAndRespond(data: Time.now.systemTimeStamp)
	}
}
