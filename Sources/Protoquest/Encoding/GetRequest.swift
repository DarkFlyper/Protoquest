import Foundation

public protocol GetRequest: Request {}

public extension GetRequest {
	var httpMethod: String { "GET" }
	
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {}
}
