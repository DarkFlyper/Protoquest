import Foundation
import HandyOperators

/// The standard composition of a client—you can compose `BaseClient` with other protocols for testing and such.
public typealias Protoclient = BaseClient & URLSessionClient

/**
A client, encapsulating the logic for sending requests to servers and processing their responses.

Only `baseURL` has to be specified by conformers—all the other members have default implementations (especially if you use the `Protoclient` type alias), intended as customization points for you to override.
*/
public protocol BaseClient {
	/// The base URL relative to which to interpret request paths.
	var baseURL: URL { get }
	
	/// The JSON encoder provided to requests.
	var requestEncoder: JSONEncoder { get }
	/// The JSON decoder provided to requests.
	var responseDecoder: JSONDecoder { get }
	
	/// Encodes a request, dispatches it, decodes its response, and publishes that.
	func send<R: Request>(_ request: R) async throws -> R.Response
	
	/// Turns a request into a raw `URLRequest`.
	func rawRequest<R: Request>(for request: R) async throws -> URLRequest
	
	/// Figures out the URL to use for a request, including URL parameters.
	func url<R: Request>(for request: R) async throws -> URL
	
	/// Provides the base URL to resolve a request's path against.
	func baseURL(for request: some Request) async throws -> URL
	
	/// Adds any common HTTP headers to a request.
	func addHeaders(to rawRequest: inout URLRequest) async throws
	
	/// Dispatches a request to the network, returning its response (data and error).
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) async throws -> Protoresponse
	
	/// Wraps a raw data task response in a `Protoresponse` for nicer ergonomics.
	func wrapResponse(data: Data, response: URLResponse) async throws -> Protoresponse
	
	// TODO: need some kind of middleware rather than this
	/// Inspects any outgoing request, e.g. for logging purposes.
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R) async
	/// Inspects any incoming response, e.g. for logging purposes.
	func traceIncoming<R: Request>(_ response: Protoresponse, for request: R, encodedAs rawRequest: URLRequest) async
}

public extension BaseClient {
	var requestEncoder: JSONEncoder { .init() }
	var responseDecoder: JSONDecoder { .init() }
	
	func send<R: Request>(_ request: R) async throws -> R.Response {
		let rawRequest = try await self.rawRequest(for: request)
		await traceOutgoing(rawRequest, for: request)
		let rawResponse = try await dispatch(rawRequest, for: request)
		await traceIncoming(rawResponse, for: request, encodedAs: rawRequest)
		return try request.decodeResponse(from: rawResponse)
	}
	
	func rawRequest<R: Request>(for request: R) async throws -> URLRequest {
		try await URLRequest(url: url(for: request)) <- { rawRequest in
			rawRequest.httpMethod = request.httpMethod
			rawRequest.setValue(request.contentType, forHTTPHeaderField: "Content-Type")
			try await addHeaders(to: &rawRequest)
			try request.encode(to: &rawRequest, using: requestEncoder)
		}
	}
	
	func url<R: Request>(for request: R) async throws -> URL {
		(URLComponents(
			url: try await baseURL(for: request) <- {
				if !request.path.isEmpty {
					$0.appendPathComponent(request.path)
				}
			},
			resolvingAgainstBaseURL: false
		)! <- {
			let urlParams = request.urlParams
			guard !urlParams.isEmpty else { return }
			$0.queryItems = urlParams.map { name, value in
				URLQueryItem(
					name: name,
					value: value.map(String.init(describing:))
				)
			}
		}).url!
	}
	
	// has to be marked async to not shadow the protocol requirement in non-async contexts (likely swift bug)
	func baseURL(for request: some Request) async -> URL {
		request.baseURLOverride ?? baseURL
	}
	
	func addHeaders(to rawRequest: inout URLRequest) {}
	
	func wrapResponse(data: Data, response: URLResponse) -> Protoresponse {
		Protoresponse(
			body: data,
			metadata: response,
			decoder: responseDecoder
		)
	}
	
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R) {}
	func traceIncoming<R: Request>(_ response: Protoresponse, for request: R, encodedAs rawRequest: URLRequest) {}
}

/// A client that uses a URLSession to dispatch its requests.
public protocol URLSessionClient: BaseClient {
	/// The session to dispatch requests on, defaulting to `URLSession.shared`.
	var urlSession: URLSession { get }
}

public extension URLSessionClient {
	var urlSession: URLSession { .shared }
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) async throws -> Protoresponse {
		let data: Data
		let response: URLResponse
		if #available(macOS 12.0, iOS 15, tvOS 15, watchOS 8, *) {
			(data, response) = try await urlSession.data(for: rawRequest)
		} else {
			(data, response) = try await withCheckedThrowingContinuation { continuation in
				urlSession.dataTask(with: rawRequest) { data, response, error in
					if let error = error {
						continuation.resume(with: .failure(error))
					} else {
						continuation.resume(with: .success((data!, response!)))
					}
				}
			}
		}
		return try await wrapResponse(data: data, response: response)
	}
}
