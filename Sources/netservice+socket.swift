import Foundation

public extension NetService
{
	func getEndpointAddress() -> EndpointAddress?
	{
		if (self.addresses == nil || self.addresses!.count == 0) {
			return nil
		}

		for data in self.addresses!
		{
			let address = SocketAddress.FromData(data).toEndpointAddress()
			if address.port > 0 {
				return address
			}
		}

		return nil
	}
}
