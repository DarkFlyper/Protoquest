import Foundation
import HandyOperators

/// An error that occurred while trying to decode a response from the server.
public protocol ResponseDecodingError: LocalizedError {
	/// The response whose (attempted) decoding caused the error.
	var toDecode: Protoresponse { get }
	/// Details specific to the error, in human-readable form.
	///
	/// The default implementation uses this to provide a description via `LocalizedError`.
	var errorDetails: String { get }
}

public extension ResponseDecodingError {
	var errorDescription: String? {
		// This is not localized, but it would only be useful to developers anyway.
		"""
		\(errorDetails)
		
		The data to decode was:
		\(String(bytes: toDecode.body, encoding: .utf8) ?? "<not valid UTF-8>")
		
		which was received with the following response:
		\("" <- { dump(toDecode.metadata, to: &$0) })
		"""
	}
}
