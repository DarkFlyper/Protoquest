import Foundation
import Combine
import HandyOperators

public protocol Protoclient {
	typealias DataTaskResult = (data: Data, response: URLResponse)
	
	var baseURL: URL { get }
	var session: URLSession { get }
	var requestEncoder: JSONEncoder { get }
	var responseDecoder: JSONDecoder { get }
	
	/// Encodes a request, dispatches it, decodes its response, and publishes that.
	func send<R: Request>(_ request: R) -> AnyPublisher<R.Response, Error>
	
	/// Turns a request into a raw `URLRequest`.
	func rawRequest<R: Request>(for request: R) throws -> URLRequest
	
	/// Figures out the URL to use for a request, including URL parameters.
	func url<R: Request>(for request: R) throws -> URL
	
	/// Adds any common HTTP headers to a request.
	func addHeaders(to rawRequest: inout URLRequest)
	
	/// Dispatches a request to the network, returning its response (data and error). Uses `session` by default.
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) -> AnyPublisher<DataTaskResult, Error>
	
	/// Inspects any outgoing request, e.g. for logging purposes.
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R)
	/// Inspects any incoming response, e.g. for logging purposes.
	func traceIncoming<R: Request>(_ response: DataTaskResult, for request: R)
}

public extension Protoclient {
	var session: URLSession { .shared }
	
	var requestEncoder: JSONEncoder { .init() }
	var responseDecoder: JSONDecoder { .init() }
	
	func send<R: Request>(_ request: R) -> AnyPublisher<R.Response, Error> {
		Just(request)
			.tryMap(rawRequest(for:))
			.also { traceOutgoing($0, for: request) }
			.flatMap { dispatch($0, for: request) }
			.also { traceIncoming($0, for: request) }
			.tryMap { [responseDecoder] in
				try request.decodeResponse(from: $0.data, using: responseDecoder)
			}
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
			url: (request.baseURLOverride ?? baseURL).appendingPathComponent(request.path),
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
	
	func dispatch<R: Request>(_ rawRequest: URLRequest, for request: R) -> AnyPublisher<DataTaskResult, Error> {
		session.dataTaskPublisher(for: rawRequest)
			.mapError { $0 }
			.eraseToAnyPublisher()
	}
	
	func traceOutgoing<R: Request>(_ rawRequest: URLRequest, for request: R) {}
	func traceIncoming<R: Request>(_ response: URLSession.DataTaskPublisher.Output, for request: R) {}
}
