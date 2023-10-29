# RoomV2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- update_room_config
class UpdateRoomConfigResponse:
	var error
	var error_message: String
	

func update_room_config_async(room_config: String, room_id: String) -> UpdateRoomConfigResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: UpdateRoomConfigResponse = UpdateRoomConfigResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/update/{roomId}".format(
		{
			"appId": Hathora.APP_ID,
			"roomId": room_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"roomConfig": room_config
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	
	HathoraEventBus.on_update_room_config.emit(result)
	return result


func update_room_config(room_config: String, room_id: String) -> Signal:
	update_room_config_async(room_config, room_id)
	return HathoraEventBus.on_update_room_config
##endregion    -- update_room_config
