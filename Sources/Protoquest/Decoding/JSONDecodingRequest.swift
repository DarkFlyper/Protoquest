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
			return try (decoderOverride ?? JSONDecoder())
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

		path: \(error.prettyCodingPath())

		\("" <- { dump(error, to: &$0) })
		"""
	}
}

extension DecodingError {
	func prettyCodingPath() -> String {
		switch self {
		case
				.typeMismatch(_, let context),
				.valueNotFound(_, let context),
				.keyNotFound(_, let context),
				.dataCorrupted(let context):
			return context.codingPath.reduce(into: "") { path, key in
				if let int = key.intValue {
					path += "[\(int)]"
				} else {
					path += ".\(key.stringValue)"
				}
			}
		@unknown default:
			return "path for unknown case \(self)"
		}
	}
}
