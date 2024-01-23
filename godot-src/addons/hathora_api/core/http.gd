## MUST be set after init() call
static var http_node: HTTPRequest

static func init(request_node: HTTPRequest) -> void:
	http_node = request_node


## Contains result of an HTTP request interpreted as JSON
## with some other useful info
class ResponseJson:
	var url: String
	var data
	var status_code: int = -1
	var error_message: String = ''
	var error
	## Used to wait for SPECIFIC http response
	## rather than waiting for ANY (random) http response
	signal request_completed


#region     -- GET/POST/DELETE async
static func get_async(url: String, headers: Array) -> ResponseJson:
	var result: ResponseJson = get_sync(url, headers)
	await result.request_completed
	return result


static func post_async(url: String, headers: Array, body: Dictionary) -> ResponseJson:
	var result: ResponseJson = post_sync(url, headers, body)
	await result.request_completed
	return result


static func delete_async(url: String, headers: Array) -> ResponseJson:
	var result: ResponseJson = delete_sync(url, headers)
	await result.request_completed
	return result
#endregion  -- GET/POST/DELETE async


#region     -- GET/POST/DELETE sync
static func get_sync(url: String, headers: Array) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform GET request without HTTPRequest node being passed to init() function")
	
	var response: ResponseJson = ResponseJson.new()
	response.url = url
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
				response.error = Hathora.Error.JsonError
				response.error_message = "Can't parse response"
			response.data = json_parse_or(raw_string, {})
			_map_error_to(response, response_code, url)
			response.request_completed.emit()
	
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	# Do the actual request
	var request_error: Error = http_node.request(url, headers, HTTPClient.METHOD_GET)
	if request_error != OK:
		response.data = {}
		response.error = Hathora.Error.InternalHttpError
		response.error_message = str(
			"Error while doing GET request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	return response


static func post_sync(url: String, headers: Array, body: Dictionary) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform POST request without HTTPRequest node being passed to init() function")
	
	var response: ResponseJson = ResponseJson.new()
	response.url = url
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
				response.error = Hathora.Error.JsonError
				response.error_message = "Can't parse response"
			response.data = json_parse_or(raw_string, {})
			_map_error_to(response, response_code, url)
			response.request_completed.emit()
	
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	# Do the actual request
	var request_error: Error = http_node.request(
		url, headers, 
		HTTPClient.METHOD_POST, JSON.stringify(body)
	)
	if request_error != OK:
		response.data = {}
		response.error = Hathora.Error.InternalHttpError
		response.error_message = str(
			"Error while doing POST request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	return response


static func delete_sync(url: String, headers: Array) -> ResponseJson:
	assert(is_instance_valid(http_node), "ASSERT! Can't perform DELETE request without HTTPRequest node being passed to init() function")
	
	var response: ResponseJson = ResponseJson.new()
	response.url = url
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
				response.error = Hathora.Error.JsonError
				response.error_message = "Can't parse response"
			response.data = json_parse_or(raw_string, {})
			_map_error_to(response, response_code, url)
			response.request_completed.emit()
	
	, CONNECT_ONE_SHOT | CONNECT_DEFERRED)
	# Do the actual request
	var request_error: Error = http_node.request(
		url, headers, HTTPClient.METHOD_DELETE
	)
	if request_error != OK:
		response.data = {}
		response.error = Hathora.Error.InternalHttpError
		response.error_message = str(
			"Error while doing POST request to `", url, 
			"`; Message: `", error_string(request_error), '`'
		)
		push_error(response.error_message)
		return response
	
	return response
#endregion  -- GET/POST/DELETE sync


static func download_file_async(url: String) -> ResponseJson:
	var response: ResponseJson = ResponseJson.new()
	response.url = url
	http_node.request_completed.connect(
		func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
			response.status_code = response_code
			_map_error_to(response, response_code, url)
			
			var json = JSON.new()
			var parse_result = json.parse(body.get_string_from_utf8())
			if parse_result != OK:
				var error_message: String = str(
					"JSON parsing error: `", json.get_error_message(),
					"` at line ", json.get_error_line()
				)
				push_error(error_message)
				response.error_message = error_message
				response.error = Hathora.Error.JsonError
			else:
				response.data = json.data
			response.request_completed.emit()
	, CONNECT_ONE_SHOT)
	
	http_node.request(url)
	await response.request_completed
	
	return response


## To-DO: explain. 
static func _map_error_to(response: ResponseJson, status_code: int, url: String) -> void:
	# Handle status codes that have the same error no matter the context
	if status_code < 200 or status_code >= 300:
		match status_code:
			400:
				response.error = Hathora.Error.BadRequest
			401:
				response.error = Hathora.Error.Unauthorized
			402:
				response.error = Hathora.Error.MustPayFirst
			403:
				response.error = Hathora.Error.Forbidden
			404:
				response.error = Hathora.Error.ApiDontExists
			422:
				response.error = Hathora.Error.ServerCantProcess
			429:
				response.error = Hathora.Error.TooManyRequests
			500:
				response.error = Hathora.Error.ServerError
			_:
				response.error = Hathora.Error.Unknown
	else:
		response.error = Hathora.Error.Ok

## Attempts to parse json string, if error occurs returns default value
static func json_parse_or(raw_string: String, default_value: Dictionary):
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
	
	return json.data


## Builds a query string like: `?param1=value1&param2=value2` based
## on [param params]. Note: params with empty values will be ignored
static func build_query_params(params: Dictionary) -> String:
	var result: String = ''
	
	for key in params.keys():
		var value = params[key]
		
		if value != '':
			result += '?' if result == '' else '&'
			result += key + '=' + value
		
	return result
