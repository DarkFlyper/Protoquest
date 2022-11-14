import Foundation

/// A raw result received from the network, also providing decoding facilities.
public struct Protoresponse {
	/// The response raw-data body.
	public var body: Data
	/// The response's metadata.
	public var metadata: URLResponse
	
	/// Most of the time, you're only ever working with HTTP connections. This property provides easy access to the relevant subclass of `URLResponse`, if applicable.
	public var httpMetadata: HTTPURLResponse? {
		metadata as? HTTPURLResponse
	}
	
	public init(body: Data, metadata: URLResponse) {
		self.body = body
		self.metadata = metadata
	}
}
