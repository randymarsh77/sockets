import Foundation

public struct EndpointAddress
{
	public var host: String
	public var port: Int

	public init(host: String, port: Int)
	{
		self.host = host
		self.port = port
	}
}
