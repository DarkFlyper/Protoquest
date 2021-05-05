# Protoquest

Simple architecture for making HTTP requests of various kinds, based on protocols and Combine.

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
	var endIndex = 20
	
    // implicitly gets @ArrayBuilder from the Request protocol
	func urlParams() -> [URLParameter] {
		("startIndex", startIndex)
		("endIndex", endIndex)
	}
	
	// ...
}
```

