import Foundation
import HandyOperators

/// A request that expects a JSON-decodable response.
public protocol JSONDecodingRequest: Request where Response: Decodable {
	/// If non-nil, overrides the decoder used to decode the response for this request.
	var decoderOverride: JSONDecoder? { get }
}

public extension JSONDecodingRequest {
	var decoderOverride: JSONDecoder? { nil }
	
	func decodeResponse(from raw: Protoresponse) throws -> Response {
		try raw.decodeJSON(using: decoderOverride)
	}
}

public extension Protoresponse {
	func decodeJSON<Body>(
		as type: Body.Type = Body.self,
		using decoderOverride: JSONDecoder? = nil
	) throws -> Body where Body: Decodable {
		do {
			return try (decoderOverride ?? decoder)
				.decode(Body.self, from: body)
		} catch let error as DecodingError {
			throw JSONDecodingError(error: error, toDecode: self)
		}
	}
}

public struct JSONDecodingError: ResponseDecodingError {
	public var error: DecodingError
	public var toDecode: Protoresponse
	
	public var errorDetails: String {
		"""
		\(error.localizedDescription)
		
		\("" <- { dump(error, to: &$0) })
		"""
	}
}
