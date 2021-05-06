import Foundation

/// A request that sends a JSON body, defaulting to itself if `Encodable`.
public protocol JSONEncodingRequest: Request {
	/// If non-nil, overrides the decoder used to decode the response for this request.
	var encoderOverride: JSONEncoder? { get }
	
	/// The type of the body to encode. `Self` often makes sense here, which it defaults to if that's`Encodable`.
	associatedtype Body: Encodable
	/// The body to encode. Defaults to `self` if that matches the type `Body`.
	var body: Body { get }
}

public extension JSONEncodingRequest {
	var httpMethod: String { "POST" }
	var contentType: String? { "application/json" }
	
	var encoderOverride: JSONEncoder? { nil }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpBody = try (encoderOverride ?? encoder).encode(body)
	}
}

public extension JSONEncodingRequest where Body == Self {
	var body: Body { self }
}
