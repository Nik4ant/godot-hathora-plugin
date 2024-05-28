# Discovery v1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_ping_service_endpoints
class GetPingServiceEndpointsResponse:
	var result: Array[Dictionary]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		self.result = data


static func get_ping_service_endpoints_async() -> GetPingServiceEndpointsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetPingServiceEndpointsResponse = GetPingServiceEndpointsResponse.new()
	var url: String = "https://api.hathora.dev/discovery/v1/ping"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_ping_service_endpoints_v1.emit(result)
	return result


static func get_ping_service_endpoints() -> Signal:
	get_ping_service_endpoints_async()
	return HathoraEventBus.on_get_ping_service_endpoints_v1
#endregion


