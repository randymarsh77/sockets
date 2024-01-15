import Foundation
import Time

public struct NetworkLatency {
	public var differenceOnRecieve: Time
	public var roundTrip: Time
}

public extension Socket {
	func ping() -> NetworkLatency {
		let start = Time.Now
		let client = Time.FromSystemTimeStamp(
			StructuredCommunicationSeed(socket: self)
				.send(data: start)
				.recieve()
				.communicate())
		let end = Time.Now
		return NetworkLatency(differenceOnRecieve: client - start, roundTrip: end - start)
	}

	func pong() {
		let _: Double =
			StructuredCommunicationSeed(socket: self)
				.recieve()
				.send(data: Time.Now.systemTimeStamp)
				.communicate()
	}
}
