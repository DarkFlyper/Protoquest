import Foundation
import Combine
import HandyOperators

/// The standard composition of a client—you can compose `BaseClient` with other protocols for testing and such.
public typealias Protoclient = BaseClient & URLSessionClient

/**
A client, encapsulating the logic for sending requests to servers and processing their responses.

Only `baseURL` has to be specified by conformers—all the other members have default implementations (especially if you use the `Protoclient` type alias), intended as customization points for you to override.
*/
public protocol BaseClient {
	/// There's no real point for typed errors most of the time.
	typealias BasicPublisher<T> = AnyPublisher<T, Error>
	
	/// The base URL relative to which to interpret request paths.
	var baseURL: URL { get }
	
	/// The JSON encoder provided to requests.
	var requestEncoder: JSONEncoder { get }
	/// The JSON decoder provided to requests.
	var responseDecoder: JSONDecoder { get }
	
	/// Encodes a request, dispatches it, decodes its response, and publishes that.
	func send<R: Request>(_ request: R) -> BasicPublisher<R.Response>
	
	/// Turns a request into a raw `URLRequest`.
	func rawRequest<R: Request>(for request: R) throws -> URLRequest
	
	/// Figures out the URL to use for a request, including URL parameters.
	func url<R: Request>(for request: R) throws -> URL
	
	/// Adds any common HTTP headers to a request.
	func addHeaders(to rawRequest: inout URLRequest)
	
	/// Dispatches a request to the network, returning its response (data and error). Uses `session` by default.
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) -> BasicPublisher<Protoresponse>
	
	/// Wraps a raw data task response in a `Protoresponse` for nicer ergonomics.
	func wrapResponse(data: Data, response: URLResponse) -> Protoresponse
	
	/// Inspects any outgoing request, e.g. for logging purposes.
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R)
	/// Inspects any incoming response, e.g. for logging purposes.
	func traceIncoming<R: Request>(_ response: Protoresponse, for request: R)
}

public extension BaseClient {
	var requestEncoder: JSONEncoder { .init() }
	var responseDecoder: JSONDecoder { .init() }
	
	func send<R: Request>(_ request: R) -> BasicPublisher<R.Response> {
		Just(request)
			.tryMap(rawRequest(for:))
			.also { traceOutgoing($0, for: request) }
			.flatMap { dispatch($0, for: request) }
			.also { traceIncoming($0, for: request) }
			.tryMap(request.decodeResponse(from:))
			.eraseToAnyPublisher()
	}
	
	func rawRequest<R: Request>(for request: R) throws -> URLRequest {
		try URLRequest(url: url(for: request)) <- { rawRequest in
			rawRequest.httpMethod = request.httpMethod
			rawRequest.setValue(request.contentType, forHTTPHeaderField: "Content-Type")
			addHeaders(to: &rawRequest)
			try request.encode(to: &rawRequest, using: requestEncoder)
		}
	}
	
	func url<R: Request>(for request: R) throws -> URL {
		(URLComponents(
			url: (request.baseURLOverride ?? baseURL) <- {
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
	
	func addHeaders(to rawRequest: inout URLRequest) {}
	
	func wrapResponse(data: Data, response: URLResponse) -> Protoresponse {
		Protoresponse(
			body: data,
			metadata: response,
			decoder: responseDecoder
		)
	}
	
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R) {}
	func traceIncoming<R: Request>(_ response: Protoresponse, for request: R) {}
}

/// A client that uses a URLSession to dispatch its requests.
public protocol URLSessionClient: BaseClient {
	/// The session to dispatch requests on, defaulting to `URLSession.shared`.
	var session: URLSession { get }
}

public extension URLSessionClient {
	var session: URLSession { .shared }
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) -> BasicPublisher<Protoresponse> {
		session.dataTaskPublisher(for: rawRequest)
			.mapError { $0 }
			.map(wrapResponse(data:response:))
			.eraseToAnyPublisher()
	}
}
