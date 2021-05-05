import Foundation

/// A request that expects a simple string response.
public protocol StringDecodingRequest: Request where Response == String {
	/// The encoding of the response string, defaulting to UTF-8.
	var responseEncoding: String.Encoding { get }
}

public extension StringDecodingRequest {
	var responseEncoding: String.Encoding { .utf8 }
	
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response {
		String(bytes: raw, encoding: .utf8)!
	}
}
