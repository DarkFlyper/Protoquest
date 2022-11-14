import Foundation
import HandyOperators

public struct Protolayer {
	let closure: (URLRequest) async throws -> Protoresponse
	
	public init(send: @escaping (_ request: URLRequest) async throws -> Protoresponse) {
		self.closure = send
	}
	
	/// Invokes this layer's send function, sending off the given request down its hierarchy and getting out a response.
	public func send(_ request: URLRequest) async throws -> Protoresponse {
		try await closure(request)
	}
	
	/// Like ``send(_:)``, but returning a `Result<Protoresponse, Error>` for your convenience.
	/// Useful because ``Result.init(catching:)`` doesn't have an `async` version (yet?).
	public func trySend(_ request: URLRequest) async -> Protoresult {
		do {
			return .success(try await send(request))
		} catch {
			return .failure(error)
		}
	}
}

extension Protolayer {
	/// Uses the provided ``URLSession`` (defaulting to `.shared`) to send a request and return the response as a ``Protoresponse``
	public static func urlSession(_ session: URLSession = .shared) -> Self {
		.init { request in
			let (body, response) = try await session.data(for: request)
			return .init(body: body, metadata: response)
		}
	}
}

public typealias Protoresult = Result<Protoresponse, Error>

public extension Protolayer {
	/// Applies the given transformation to the request before sending it off to this layer.
	func transformRequest(
		_ transform: @escaping (inout URLRequest) async throws -> Void
	) -> Self {
		.init { request in
			try await send(request <- transform)
		}
	}
	
	/// Provides the request to the given function before sending it off to this layer.
	func readRequest(_ read: @escaping (URLRequest) async throws -> Void) -> Self {
		.init { request in
			try await read(request)
			return try await send(request)
		}
	}
	
	/// Applies the given transformation to the response once it leaves this layer.
	func transformResponse(
		_ transform: @escaping (inout Protoresponse) async throws -> Void
	) -> Self {
		.init { try await send($0) <- transform }
	}
	
	/// Provides the response to the given function once it leaves this layer.
	func readResponse(_ read: @escaping (Protoresponse) async throws -> Void) -> Self {
		.init { try await send($0) <- read }
	}
	
	func readResult(_ read: @escaping (Protoresult) async throws -> Void) -> Self {
		.init { try await (trySend($0) <- read).get() }
	}
	
	/// Once an exchange has completed, whether successful or not, provides the request and its result (response or error) to the given function.
	func readExchange(_ read: @escaping (URLRequest, Protoresult) async throws -> Void) -> Self {
		.init { request in
			let result = await trySend(request)
			try await read(request, result)
			return try result.get()
		}
	}
	
	/// Wraps this layer in a new layer, able to apply any desired transformations on top.
	/// This is equivalent to capturing the layer in a new ``Protolayer``, but more convenient when chaining layer functions.
	func wrap(
		_ layer: @escaping (URLRequest, Self) async throws -> Protoresponse
	) -> Self {
		.init { try await layer($0, self) }
	}
}

public extension Protolayer {
	/// Prints outgoing requests and incoming responses for any traffic passing through this layer.
	/// - Parameter maxBodyLength: maximum number of characters to print when logging response bodies
	func printExchanges(maxBodyLength: Int = 1000) -> Self {
		.init { request in
			let path = request.url!.path
			print("\(path): sending \(request.httpMethod!) request to", request.url!)
			print(String(data: request.httpBody ?? Data(), encoding: .utf8)!)
			
			return try await send(request) <- { response in
				print("\(path): received response:")
				if response.body.count < maxBodyLength {
					print((try? response.decodeString(using: .utf8)) ?? "<undecodable>")
				} else {
					print("<\(response.body.count) bytes>")
				}
			}
		}
	}
}
