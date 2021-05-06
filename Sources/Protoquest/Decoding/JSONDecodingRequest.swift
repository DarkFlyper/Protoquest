import Foundation
import HandyOperators

/// A request that expects a JSON-decodable response.
public protocol JSONDecodingRequest: Request where Response: Decodable {
	/// If non-nil, overrides the decoder used to decode the response for this request.
	var decoderOverride: JSONDecoder? { get }
}

public extension JSONDecodingRequest {
	var decoderOverride: JSONDecoder? { nil }
	
	func decodeResponse(from raw: DataTaskResult, using decoder: JSONDecoder) throws -> Response {
		do {
			return try (decoderOverride ?? decoder).decode(Response.self, from: raw.data)
		} catch let error as DecodingError {
			throw JSONDecodingError(error: error, toDecode: raw)
		}
	}
}

private struct JSONDecodingError: LocalizedError {
	var error: DecodingError
	var toDecode: DataTaskResult
	
	var errorDescription: String? {
		"""
		\(error.localizedDescription)
		
		\("" <- { dump(error, to: &$0) })
		
		The data to decode was:
		\(String(bytes: toDecode.data, encoding: .utf8)!)
		
		which was received with the following response:
		\("" <- { dump(toDecode.response, to: &$0) })
		"""
	}
}
