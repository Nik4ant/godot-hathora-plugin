class_name Http extends Object

## MUST be set after init() call
static var http_node: HTTPRequest
# Note(Nik4ant): I wonder if it would be better to just pass 
# HTTPRequest node as a param to GET/POST/DELETE functions below...
static func init(request_node: HTTPRequest) -> void:
	http_node = request_node


const HathoraError = preload("res://addons/hathora_api/core/error.gd").HathoraError
## Contains result of an HTTP request interpreted as JSON
class ResponseJson:
	var data: Dictionary
	var status_code: int = -1
	var error_message: String = ''
	## Used to wait for SPECIFIC http response
	## rather than waiting for ANY (random) http response
	## (Helpful for making multiple requests at once)
	signal _request_completed


#region     -- GET/POST/DELETE
static func GET(url: String, headers: Array[String]) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform GET request without HTTPRequest node being passed to init() function")
	var response: ResponseJson = ResponseJson.new()
	# Handle response
	http_node.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			response.status_code = response_code
			response.data = json_parse_or(body.get_string_from_utf8(), {})
			response._request_completed.emit()
	, CONNECT_ONE_SHOT)
	
	# Do the actual request
	var request_error: Error = http_node.request(url, headers, HTTPClient.METHOD_GET)
	if request_error != OK:
		response.data = {}
		response.error_message = str(
			"Error while doing GET request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	await response._request_completed
	return response


static func POST(url: String, headers: Array[String], body: Dictionary) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform GET request without HTTPRequest node being passed to init() function")
	var response: ResponseJson = ResponseJson.new()
	# Handle response
	http_node.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			response.status_code = response_code
			var raw_string: String = body.get_string_from_utf8()
			response.data = json_parse_or(raw_string, {"__error__": raw_string})
			response._request_completed.emit()
	, CONNECT_ONE_SHOT)
	
	# Do the actual request
	var request_error: Error = http_node.request(
		url, headers,
		HTTPClient.METHOD_POST, JSON.stringify(body)
	)
	if request_error != OK:
		response.data = {}
		response.error_message = str(
			"Error while doing POST request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	await response._request_completed
	return response
#endregion  -- GET/POST/DELETE


## Attempts to parse json string, if error occurs returns default value
## (Error is printed via push_error)
static func json_parse_or(raw_string: String, default_value):
	# Note: Could have used JSON.parse_string(), but it doesn't return 
	# a proper error message, making it harder to debug
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(raw_string)
	
	if parse_result != OK:
		push_error(
			"JSON parsing error: ", json.get_error_message(), 
			" in `", raw_string, "` at line ", json.get_error_line()
		)
		breakpoint
		return default_value
	return json.data
