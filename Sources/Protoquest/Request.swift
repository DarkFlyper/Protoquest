import Foundation
import ArrayBuilder
import HandyOperators

/// Essentially a URLQueryItem, but implicitly encoding its value as its description.
public typealias URLParameter = (name: String, value: Any?)

public protocol Request {
	/// A path to take relative to the client's base URL, e.g. `"user/details/\(userID)"`.
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
	func encode(to rawRequest: inout URLRequest) throws
	
	/// The expected response type to this request.
	associatedtype Response
	/// Decodes the response received for this response into the expected response type.
	func decodeResponse(from raw: Protoresponse) throws -> Response
	
	/// Creates a ready-to-send URLRequest to ``url(relativeTo:)`` configured through ``configure(_:)``.
	func encode(baseURL: URL) throws -> URLRequest
	/// The url to send the request to, including the ``path`` & ``encodeQueryItems()`` and respecting ``baseURLOverride``.
	func url(relativeTo baseURL: URL) -> URL
	/// Configures a request by settings its method (``httpMethod``), content type (``contentType``), and body (``encode(to:)``)
	func configure(_ rawRequest: inout URLRequest) throws
	/// Turns the ``URLParameter``s in ``urlParams`` into ``URLQueryItem``s, or `nil` if empty.
	func encodeQueryItems() -> [URLQueryItem]?
}

public extension Request {
	var baseURLOverride: URL? { nil }
	var path: String { "" }
	var contentType: String? { nil }
	
	var urlParams: [URLParameter] { [] }
	
	func encodeQueryItems() -> [URLQueryItem]? {
		urlParams.nonEmptyOptional?.map { name, value in
			URLQueryItem(
				name: name,
				value: value.map(String.init(describing:))
			)
		}
	}
	
	private func appendPath(to url: inout URL) {
		if !path.isEmpty {
			url.appendPathComponent(path)
		}
	}
	
	func encode(baseURL: URL) throws -> URLRequest {
		try URLRequest(url: url(relativeTo: baseURL)) <- configure
	}
	
	func url(relativeTo baseURL: URL) -> URL {
		(URLComponents(
			url: (baseURLOverride ?? baseURL) <- appendPath(to:),
			resolvingAgainstBaseURL: false
		)! <- {
			$0.queryItems = encodeQueryItems()
		}).url!
	}
	
	func configure(_ rawRequest: inout URLRequest) throws {
		rawRequest.httpMethod = httpMethod
		rawRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
		try encode(to: &rawRequest)
	}
}

extension Collection {
	var nonEmptyOptional: Self? {
		isEmpty ? nil : self
	}
}
