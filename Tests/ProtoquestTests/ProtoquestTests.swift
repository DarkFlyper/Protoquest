import XCTest
import Protoquest

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
	}
}

struct TestClient: Protoclient {
	let baseURL = URL(string: "https://test.com")!
}

struct TestRequest: JSONJSONRequest, Encodable {
	var path: String { "example/path" }
	
	var text: String
	
	struct Response: Decodable {
		var value: Int
	}
}

struct TestURLParameterRequest: GetRequest, StringDecodingRequest, Encodable {
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
