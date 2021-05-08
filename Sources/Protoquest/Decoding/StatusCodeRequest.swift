import Foundation

/// A request that expects no response body, only expecting response metadata.
///
/// - Note: The request doesn't actually provide the status code or headers—you'd handle that for all requests somewhere in the client, or provide a custom implementation of `decodeResponse` instead..
public protocol StatusCodeRequest: Request where Response == Void {}

public extension StatusCodeRequest {
	func decodeResponse(from raw: Protoresponse) throws -> Response {}
}
