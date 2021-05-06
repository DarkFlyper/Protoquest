import Foundation

/// A request that expects no response body, only looking at the status code.
public protocol StatusCodeRequest: Request where Response == Void {}

public extension StatusCodeRequest {
	func decodeResponse(from raw: DataTaskResult, using decoder: JSONDecoder) throws -> Response {}
}
