# BuildV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- delete_build
class DeleteBuildResponse:
	var error
	var error_message: String
	

func delete_build_async(build_id: int) -> DeleteBuildResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DeleteBuildResponse = DeleteBuildResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/delete/{buildId}".format(
		{
			"appId": Hathora.APP_ID,
			"buildId": build_id
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
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [404, 422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	
	HathoraEventBus.on_delete_build.emit(result)
	return result


func delete_build(build_id: int) -> Signal:
	delete_build_async(build_id)
	return HathoraEventBus.on_delete_build
##endregion    -- delete_build
