# DiscoveryV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_ping_service_endpoints
class GetPingServiceEndpointsResponse:
	var error
	var error_message: String
	
	var result: Array[Dictionary]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(part)


func get_ping_service_endpoints_async() -> GetPingServiceEndpointsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetPingServiceEndpointsResponse = GetPingServiceEndpointsResponse.new()
	var url: String = "https://api.hathora.dev/discovery/v1/ping"
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json"]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# HUMAN! I need your help - write error messages pls
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_ping_service_endpoints.emit(result)
	return result


func get_ping_service_endpoints() -> Signal:
	get_ping_service_endpoints_async()
	return HathoraEventBus.on_get_ping_service_endpoints
##endregion    -- get_ping_service_endpoints
