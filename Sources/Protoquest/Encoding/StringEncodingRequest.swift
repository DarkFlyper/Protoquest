import Foundation

/// A request whose sent body is simply a string..
public protocol StringEncodingRequest: Request {
	/// The body to encode and send.
	var body: String { get }
	/// The encoding to encode the string body with, defaulting to UTF-8.
	var requestEncoding: String.Encoding { get }
}

public extension StringEncodingRequest {
	var contentType: String? { "text/plain" }
	var requestEncoding: String.Encoding { .utf8 }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpBody = body.data(using: requestEncoding)
	}
}
