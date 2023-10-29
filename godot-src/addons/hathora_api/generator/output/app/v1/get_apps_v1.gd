# AppV1
const ApplicationWithDeployment = preload("res://addons/hathora_api/api/common_types.gd").ApplicationWithDeployment
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_apps
class GetAppsResponse:
	var error
	var error_message: String
	
	var result: Array[ApplicationWithDeployment]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(ApplicationWithDeployment.deserialize(part))


func get_apps_async() -> GetAppsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetAppsResponse = GetAppsResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/list"
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
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
	
	HathoraEventBus.on_get_apps.emit(result)
	return result


func get_apps() -> Signal:
	get_apps_async()
	return HathoraEventBus.on_get_apps
##endregion    -- get_apps
