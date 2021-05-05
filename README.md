# Protoquest

Simple architecture for making HTTP requests of various kinds, based on protocols and Combine.

## Features

Built-in request types (you can always add your own):
- bodiless requests (e.g. `GET`)
- JSON-body requests (e.g. `POST`)
- string-body requests (encoding customizable)
- raw data requests (e.g. file uploads)
- multipart requests (TODO)

Built-in response types (also expandable):
- bodiless responses (just status codes)
- JSON responses
- string responses (encoding customizable)
- raw data responses (e.g. file downloads)

Protoquest also offers some convenient type aliases for combining these:
- `GetJSONRequest` (no body request, JSON response)
- `JSONJSONRequest` (JSON request, JSON response)
- …and many more in this style

The library also supports URL parameters, along with a handy way to express them using function builders (via [ArrayBuilder](https://github.com/juliand665/ArrayBuilder)):

```swift
struct MyRequest: GetJSONRequest {
	var startIndex = 0
	var endIndex: Int?
	
    // implicitly gets @ArrayBuilder from the Request protocol
	func urlParams() -> [URLParameter] {
		("startIndex", startIndex)
		if let endIndex = endIndex {
			("endIndex", endIndex)
		}
	}
}
```

## Examples

For these examples, we're working with the most basic form of a client which just provides a base URL for request paths:

```swift
struct TestClient: Protoclient {
	let baseURL = URL(string: "https://test.com")!
}

let client = TestClient()
```

### Basic JSON-JSON Request

```swift
struct TestRequest: JSONJSONRequest, Encodable {
	var path: String { "example/path" }
	
	var text: String
	
	struct Response: Decodable {
		var value: Int
	}
}

client.send(TestRequest(text: "hi!"))
```

This sends a request to https://test.com/example/path, encoding a JSON body (`{"text": "hi!"}`), defaulting the HTTP method to "POST" (overridable in the request) and the `Content-Type` header to `application/json`. When it gets a response, it tries to decode it into a `TestRequest.Response`: a JSON object with a single property `value` whose value is an `Int`.

### Basic URL Parameters

```swift
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

client.send(TestURLParameterRequest(param1: "te-st"))
```

This sends a (bodiless) GET request to https://test.com/url_parameters/query_items?one=te%26st&two=42 (you'll notice the URL-incompatible character `&` in `param1` was percent-encoded to `%26`), in return expecting a simple string. Note how easy the function builder implicitly added to `urlParams` from the `Request` protocol makes conditional parameters.

