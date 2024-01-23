# BuildV1
const Build = preload("res://addons/hathora_api/api/common_types.gd").Build
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_builds
class GetBuildsResponse:
	var error
	var error_message: String
	
	var result: Array[Build]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(Build.deserialize(part))


static func get_builds_async() -> GetBuildsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBuildsResponse = GetBuildsResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/list".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_builds.emit(result)
	return result


static func get_builds() -> Signal:
	get_builds_async()
	return HathoraEventBus.on_get_builds
#endregion    -- get_builds
