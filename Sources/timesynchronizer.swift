import Foundation
import Time

public class TimeSynchronizer
{
	var systemLatency: Double = Time.Interval(milliseconds: 400)
	var targets: Array = Array<(Double, Double)>()

	public init() {}

	public func addTarget(_ target: Socket) -> Int
	{
		let (roundTrip, differenceOnRecieve) = target.ping()
		let index = targets.count
		self.targets.append((roundTrip, differenceOnRecieve))
		return index
	}

	public func syncTarget(token: Int, time: Double) -> (Double, Double)
	{
		let (roundTrip, differenceOnRecieve) = self.targets[token]

		let start = hostToTarget(host: time + self.systemLatency, roundTrip: roundTrip, difference: differenceOnRecieve)
		let guess = hostToTarget(host: time, roundTrip: roundTrip, difference: differenceOnRecieve)

		return (start, guess)
	}
}

func hostToTarget(host: Double, roundTrip: Double, difference: Double) -> Double
{
	let hostTimeOnArrival = host + roundTrip / 2.0
	let clientTime = hostTimeOnArrival + difference
	return clientTime
}
