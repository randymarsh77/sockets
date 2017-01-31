import Foundation
import Time

public extension Socket
{
	public func ping() -> (Double, Double)
	{
		let start = Time.Current()
		let clientTime: Double =
			StructuredCommunicationSeed(socket: self)
				.send(data: start)
				.recieve()
				.communicate()
		let end = Time.Current()
		return (end - start, clientTime - start)
	}

	public func pong()
	{
		let _: Double =
			StructuredCommunicationSeed(socket: self)
				.recieve()
				.send(data: Time.Current())
				.communicate()
	}
}
