import Foundation

/// A request whose sent body is simply some raw data.
public protocol RawBodyRequest: Request {
	/// The body data to send.
	var body: Data { get }
}

public extension RawBodyRequest {
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpBody = body
	}
}
