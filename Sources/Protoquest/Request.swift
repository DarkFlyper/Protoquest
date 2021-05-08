import Foundation
import ArrayBuilder

/// Essentially a URLQueryItem, but implicitly encoding its value as its description.
public typealias URLParameter = (name: String, value: Any?)

public protocol Request {
	/// A path to take relative to the client's base URL, e.g. `"/user/\(userID)"`.
	var path: String { get }
	/// If non-nil, the request's path is taken relative to this URL rather than the client's base URL.
	var baseURLOverride: URL? { get }
	
	/// The HTTP method the request uses (e.g. "GET", "POST", …).
	var httpMethod: String { get }
	/// The content type of the request's body, if applicable.
	var contentType: String? { get }
	
	/// The URL parameters to encode into the URL for this request, e.g. `("startIndex", 20)` => `https://your.url/your/path?startIndex=20`.
	@ArrayBuilder<URLParameter>
	var urlParams: [URLParameter] { get }
	
	/// Encodes this request into the given raw URL request, usually just setting its `httpBody` property.
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws
	
	/// The expected response type to this request.
	associatedtype Response
	/// Decodes the response received for this response into the expected response type.
	func decodeResponse(from raw: Protoresponse) throws -> Response
}

public extension Request {
	var baseURLOverride: URL? { nil }
	var path: String { "" }
	var contentType: String? { nil }
	
	var urlParams: [URLParameter] { [] }
}
