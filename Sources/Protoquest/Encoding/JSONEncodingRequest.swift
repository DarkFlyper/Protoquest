import Foundation

public protocol JSONEncodingRequest: Request {
	/// If non-nil, overrides the decoder used to decode the response for this request.
	var encoderOverride: JSONEncoder? { get }
	
	associatedtype Body: Encodable
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
