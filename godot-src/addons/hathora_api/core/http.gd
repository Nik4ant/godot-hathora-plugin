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
	var error: HathoraError
	## Used to wait for SPECIFIC http response
	## rather than waiting for ANY (random) http response
	## (Might be helpful for making multiple requests at once)
	signal request_completed


#region     -- GET/POST async
static func get_async(url: String, headers: Array[String]) -> ResponseJson:
	var result: ResponseJson = get_sync(url, headers)
	await result.request_completed
	return result


static func post_async(url: String, headers: Array[String], body: Dictionary) -> ResponseJson:
	var result: ResponseJson = post_sync(url, headers, body)
	await result.request_completed
	return result
#endregion  -- GET/POST async


#region     -- GET/POST sync
static func get_sync(url: String, headers: Array[String]) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform GET request without HTTPRequest node being passed to init() function")
	
	var response: ResponseJson = ResponseJson.new()
	http_node.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			response.status_code = response_code
			# Parse result (if any)
			var json: JSON = JSON.new()
			var raw_string: String = body.get_string_from_utf8()
			var parse_result: Error = json.parse(raw_string)
			if parse_result != OK:
				push_error(
					"JSON parsing error: ", json.get_error_message(), 
					" in `", raw_string, "` at line ", json.get_error_line()
				)
				response.error = HathoraError.JsonError
				response.error_message = "Can't parse response"
			response.data = json_parse_or(raw_string, {})
			_map_error_to(response, response_code, url)
			response.request_completed.emit()
	
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED | CONNECT_REFERENCE_COUNTED)
	# Do the actual request
	var request_error: Error = http_node.request(url, headers, HTTPClient.METHOD_GET)
	if request_error != OK:
		response.data = {}
		response.error = HathoraError.InternalHttpError
		response.error_message = str(
			"Error while doing GET request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	return response


static func post_sync(url: String, headers: Array[String], body: Dictionary) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform GET request without HTTPRequest node being passed to init() function")
	
	var response: ResponseJson = ResponseJson.new()
	http_node.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			response.status_code = response_code
			# Parse result (if any)
			var json: JSON = JSON.new()
			var raw_string: String = body.get_string_from_utf8()
			var parse_result: Error = json.parse(raw_string)
			if parse_result != OK:
				push_error(
					"JSON parsing error: ", json.get_error_message(), 
					" in `", raw_string, "` at line ", json.get_error_line()
				)
				response.error = HathoraError.JsonError
				response.error_message = "Can't parse response"
			response.data = json_parse_or(raw_string, {})
			_map_error_to(response, response_code, url)
			response.request_completed.emit()
	
	, CONNECT_ONE_SHOT)
	# Do the actual request
	var request_error: Error = http_node.request(
		url, headers, 
		HTTPClient.METHOD_POST, JSON.stringify(body)
	)
	if request_error != OK:
		response.data = {}
		response.error = HathoraError.InternalHttpError
		response.error_message = str(
			"Error while doing GET request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	return response
#endregion  -- GET/POST sync


## To-DO: explain. 
## TL;DR checks the most common errors and maps them to response object
static func _map_error_to(response: ResponseJson, status_code: int, url: String) -> void:
	# Handle status codes that have the same error no matter the context
	if status_code < 200 or status_code >= 300:
		match status_code:
			404:
				response.error = HathoraError.ApiDontExists
				response.error_message = str(
					"Api endpoint `", url, "` doesn't exist"
				)
				push_error(response.error_message)
			500:
				response.error = HathoraError.ServerError
				response.error_message = "Hathora servers don't respond"
				push_error(response.error_message)
			_:
				response.error = HathoraError.Unknown
				response.error_message = str(
					"Unknown error status code.\nUrl: `", url,
					"`; Status code: ", status_code, "; Response data: ", response.data
				)


## Attempts to parse json string, if error occurs returns default value
## (Error is printed via push_error)
static func json_parse_or(raw_string: String, default_value: Dictionary) -> Dictionary:
	# Note: Could have used JSON.parse_string(), but it doesn't return 
	# a proper error message, making it harder to debug
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(raw_string)
	
	if parse_result != OK:
		push_error(
			"JSON parsing error: ", json.get_error_message(), 
			" in `", raw_string, "` at line ", json.get_error_line()
		)
		return default_value
	# Note: Most likely an error
	if json.data is String:
		return {"__message__": json.data}
	return json.data
