import Foundation

public protocol StringEncodingRequest: Request {
	var body: String { get }
	var requestEncoding: String.Encoding { get }
}

public extension StringEncodingRequest {
	var contentType: String? { "text/plain" }
	var requestEncoding: String.Encoding { .utf8 }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpBody = body.data(using: requestEncoding)
	}
}
