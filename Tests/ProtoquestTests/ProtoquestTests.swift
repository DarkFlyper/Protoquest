import XCTest
import Protoquest
import Combine

final class ProtoquestTests: XCTestCase {
	let client = TestClient()
	
	func testExample() throws {
		let raw = try client.rawRequest(for: TestRequest(text: "hi!"))
		XCTAssertEqual(raw.url!.absoluteString, "https://test.com/example/path")
		XCTAssertEqual(raw.httpMethod, "POST")
		XCTAssertEqual(raw.value(forHTTPHeaderField: "Content-Type"), "application/json")
		let json = String(bytes: raw.httpBody!, encoding: .utf8)!
		XCTAssertEqual(json, #"{"text":"hi!"}"#)
	}
	
	func testURLParams() throws {
		let raw = try client.rawRequest(for: TestURLParameterRequest(param1: "te&st"))
		XCTAssertEqual(raw.url!.absoluteString, "https://test.com/url_parameters/query_items?one=te%26st&two=42")
		XCTAssertEqual(raw.httpMethod, "GET")
		XCTAssertNil(raw.value(forHTTPHeaderField: "Content-Type"))
		XCTAssertNil(raw.httpBody)
		
		let without = TestURLParameterRequest(param1: "test", shouldIncludeSecondParam: false)
		let rawWithout = try client.rawRequest(for: without)
		XCTAssertEqual(rawWithout.url!.absoluteString, "https://test.com/url_parameters/query_items?one=test")
	}
	
	func testSending() async throws {
		let string = try await client.send(TestGetStringRequest())
		XCTAssertEqual(string, "echo ")
		
		let json = try await client.send(TestJSONStringRequest(body: .init(text: "hello!")))
		XCTAssertEqual(json, #"echo {"text":"hello!"}"#)
	}
}

struct TestClient: Protoclient {
	let baseURL = URL(string: "https://test.com")!
	
	let echo = "echo ".data(using: .utf8)!
	
	func dispatch<R>(_ rawRequest: URLRequest, for request: R) async throws -> Protoresponse where R : Request {
		Protoresponse(
			body: echo + (rawRequest.httpBody ?? Data()),
			metadata: URLResponse(),
			decoder: JSONDecoder()
		)
	}
}

struct TestRequest: JSONJSONRequest, Encodable {
	var path: String { "example/path" }
	
	var text: String
	
	struct Response: Decodable {
		var value: Int
	}
}

struct TestURLParameterRequest: GetRequest, StringDecodingRequest {
	var path: String { "url_parameters/query_items" }
	
	var param1: String
	var param2 = 42
	var shouldIncludeSecondParam = true
	
	var urlParams: [URLParameter] {
		("one", param1)
		if shouldIncludeSecondParam {
			("two", param2)
		}
	}
}

struct TestGetStringRequest: GetRequest, StringDecodingRequest {}

struct TestJSONStringRequest: JSONEncodingRequest, StringDecodingRequest {
	struct Body: Encodable {
		var text: String
	}
	
	var body: Body
}
