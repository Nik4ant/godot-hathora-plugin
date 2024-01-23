# AppV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- delete_app
class DeleteAppResponse:
	var error
	var error_message: String

static func delete_app_async() -> DeleteAppResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DeleteAppResponse = DeleteAppResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/delete/{appId}".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.delete_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	
	HathoraEventBus.on_delete_app.emit(result)
	return result


static func delete_app() -> Signal:
	delete_app_async()
	return HathoraEventBus.on_delete_app
#endregion    -- delete_app
