import XCTest
import Protoquest

final class ProtoquestTests: XCTestCase {
	let client = TestClient()
	
	func testExample() throws {
		let raw = try client.rawRequest(for: TestRequest(text: "hi!"))
		let json = String(bytes: raw.httpBody!, encoding: .utf8)!
		XCTAssertEqual(raw.url!.absoluteString, "https://test.com/example/path")
		XCTAssertEqual(raw.httpMethod, "POST")
		XCTAssertEqual(raw.value(forHTTPHeaderField: "Content-Type"), "application/json")
		XCTAssertEqual(json, #"{"text":"hi!"}"#)
	}
}

struct TestClient: Protoclient {
	let baseURL = URL(string: "https://test.com")!
}

struct TestRequest: JSONJSONRequest, Encodable {
	var path: String { "example/path" }
	
	var text: String
	
	struct Response: Decodable {
		var text: String
	}
}
