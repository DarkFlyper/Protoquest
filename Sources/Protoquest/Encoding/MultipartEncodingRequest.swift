import Foundation
import ArrayBuilder
import HandyOperators

/// A request that is encoded as a multipart form.
public protocol MultipartEncodingRequest: Request, Encodable {
	/// If non-nil, overrides the decoder used to decode the response for this request.
	var encoderOverride: JSONEncoder? { get }
	
	@ArrayBuilder<(String, MultipartPart)>
	func parts() throws -> [(String, MultipartPart)]
}

private let multipartBoundary = "boundary-\(UUID())-boundary"
public extension MultipartEncodingRequest {
	var httpMethod: String { "POST" }
	var contentType: String? { "multipart/form-data; charset=utf-8; boundary=\(multipartBoundary)" }
	
	var encoderOverride: JSONEncoder? { nil }
	
	func encode(to rawRequest: inout URLRequest) throws {
		let encoder = encoderOverride ?? JSONEncoder()
		let rawBoundary = "--\(multipartBoundary)\r\n".data(using: .utf8)!
		
		rawRequest.httpBody = try rawBoundary <- {
			for (name, part) in try parts() {
				$0 += try part.makeFormData(name: name, using: encoder)
				$0 += rawBoundary
			}
		}
	}
}

public struct MultipartPart {
	/// This part's `Content-Type` header.
	var contentType: String?
	/// Additional parts to add to the `Content-Disposition` header.
	var disposition: [String]
	/// Encodes this part's body to raw data.
	var encodeBody: (JSONEncoder) throws -> Data
	
	public init(
		contentType: String? = nil,
		encodeBody: @escaping (JSONEncoder) throws -> Data,
		@ArrayBuilder<String> disposition: () -> [String] = { [] }
	) {
		self.contentType = contentType
		self.encodeBody = encodeBody
		self.disposition = disposition()
	}
	
	/// Creates its body from the given value, defaulting to a `Content-Type` header of `application/json`.
	public static func json<Value: Encodable>(
		value: Value,
		contentType: String? = "application/json"
	) -> Self {
		.init(contentType: contentType) {
			try $0.encode(value)
		}
	}
	
	/// Creates its body by loading a file at the given URL. Customizing `contentType` recommended!
	/// Also provides a `filename=...` content disposition multipart header based on the given URL.
	public static func file(
		at url: URL,
		contentType: String? = nil
	) -> Self {
		.init(contentType: contentType) { encoder in
			try Data(contentsOf: url)
		} disposition: {
			"filename=\"\(url.lastPathComponent)\""
		}
	}
	
	func makeFormData(name: String, using encoder: JSONEncoder) throws -> Data {
		let fullDisposition = Array<String> {
			"form-data"
			"name=\"\(name)\""
			disposition
		}.joined(separator: "; ")
		
		let headers = Array<String> {
			"Content-Disposition: \(fullDisposition)"
			contentType.map { "Content-Type: \($0)" }
		}
		
		let data = try Array<Data> {
			headers.map { $0.data(using: .utf8)! }
			Data()
			try encodeBody(encoder)
			Data()
		}
		
		return Data(data.joined(separator: "\r\n".data(using: .utf8)!))
	}
}
