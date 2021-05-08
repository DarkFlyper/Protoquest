import Foundation
import HandyOperators

/// A request that expects a simple string response.
public protocol StringDecodingRequest: Request where Response == String {
	/// The encoding of the response string, defaulting to UTF-8.
	var responseEncoding: String.Encoding { get }
}

public extension StringDecodingRequest {
	var responseEncoding: String.Encoding { .utf8 }
	
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		try raw.decodeString(using: responseEncoding)
	}
}

public extension Protoresponse {
	func decodeString(using encoding: String.Encoding) throws -> String {
		try String(bytes: body, encoding: encoding)
			??? StringDecodingError(toDecode: self, attemptedEncoding: encoding)
	}
}

public struct StringDecodingError: ResponseDecodingError {
	public var toDecode: Protoresponse
	public var attemptedEncoding: String.Encoding
	
	public var errorDetails: String {
		"The string was not decodable as \(attemptedEncoding)."
	}
}
