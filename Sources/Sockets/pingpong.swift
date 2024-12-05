import Foundation
import Time

public struct NetworkLatency {
	public var differenceOnReceive: Time
	public var roundTrip: Time
}

extension Socket {
	public func ping() -> NetworkLatency {
		let start = Time.now
		let client = Time.fromSystemTimeStamp(
			StructuredCommunicationSeed(socket: self)
				.send(data: start)
				.receive()
				.communicate())
		let end = Time.now
		return NetworkLatency(differenceOnReceive: client - start, roundTrip: end - start)
	}

	public func pong() {
		let _: Double =
			StructuredCommunicationSeed(socket: self)
			.receive()
			.send(data: Time.now.systemTimeStamp)
			.communicate()
	}
}
