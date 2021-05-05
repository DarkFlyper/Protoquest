import Foundation

public typealias GetJSONRequest = GetRequest & JSONDecodingRequest
public typealias GetDataRequest = GetRequest & RawDataRequest
public typealias GetStringRequest = GetRequest & StringDecodingRequest

public typealias JSONJSONRequest = JSONEncodingRequest & JSONDecodingRequest
public typealias JSONStatusCodeRequest = JSONEncodingRequest & StatusCodeRequest

public typealias StringStringRequest = StringEncodingRequest & StringDecodingRequest
