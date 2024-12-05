import Foundation
import Time

public struct TimeSynchronization {
	public var syncTime: Time
	public var receiveGuess: Time
}

public class TimeSynchronizer {
	var systemLatency = Time.fromInterval(400, unit: .milliseconds)
	var targets = [NetworkLatency]()

	public init() {}

	public func addTarget(_ target: Socket) -> Int {
		let latency = target.ping()
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
