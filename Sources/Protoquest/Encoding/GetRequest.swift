import Foundation

/// A request that sends no body, defaulting to the `GET` HTTP method.
public protocol GetRequest: Request {}

public extension GetRequest {
	var httpMethod: String { "GET" }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {}
}
