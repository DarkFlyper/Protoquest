import Foundation

/// A request that expects a binary data response.
public protocol RawDataRequest: Request where Response == Data {}

public extension RawDataRequest {
	func decodeResponse(from raw: Data, using decoder: JSONDecoder) throws -> Response { raw }
}
