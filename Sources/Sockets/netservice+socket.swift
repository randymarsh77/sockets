#if os(macOS) || os(iOS)
	import class Foundation.NetService
#endif
#if os(Linux)
	import NetService
#endif

extension NetService {
	public func getEndpointAddress() -> EndpointAddress? {
		if self.addresses == nil || self.addresses!.count == 0 {
			return nil
		}

		for data in self.addresses! {
			let address = SocketAddress.fromData(data).toEndpointAddress()
			if address.port > 0 {
				return address
			}
		}

		return nil
	}
}
