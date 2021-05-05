import Foundation

public protocol RawBodyRequest: Request {
	var body: Data { get }
}

public extension RawBodyRequest {
	func encode(to rawRequest: inout URLRequest, using encoder: JSONEncoder) throws {
		rawRequest.httpBody = body
	}
}
