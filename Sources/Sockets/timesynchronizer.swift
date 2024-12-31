import Foundation
import Time

public struct TimeSynchronization: Sendable {
	public let syncTime: Time
	public let receiveGuess: Time
}

public actor TimeSynchronizer: Sendable {
	var systemLatency = Time.fromInterval(400, unit: .milliseconds)
	var targets = [NetworkLatency]()

	public init() {}

	public func addTarget(_ target: Socket) async -> Int {
		let latency = await target.ping()
		let index = targets.count
		self.targets.append(latency)
		return index
	}

	public func syncTarget(token: Int, time: Time) -> TimeSynchronization {
		let latency = self.targets[token]

		let start = hostToTarget(host: time + self.systemLatency, latency: latency)
		let guess = hostToTarget(host: time, latency: latency)

		return TimeSynchronization(syncTime: start, receiveGuess: guess)
	}
}

func hostToTarget(host: Time, latency: NetworkLatency) -> Time {
	let hostTimeOnArrival =
		host + Time.fromInterval(latency.roundTrip.value / 2.0, unit: latency.roundTrip.unit)
	let clientTime = hostTimeOnArrival + latency.differenceOnReceive
	return clientTime
}
