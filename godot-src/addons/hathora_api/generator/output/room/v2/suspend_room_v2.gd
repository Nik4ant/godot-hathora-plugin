# RoomV2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- suspend_room
class SuspendRoomResponse:
	var error
	var error_message: String

static func suspend_room_async(room_id: String) -> SuspendRoomResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: SuspendRoomResponse = SuspendRoomResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/suspend/{roomId}".format(
		{
			"appId": Hathora.APP_ID,
			"roomId": room_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	, {}

	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	
	HathoraEventBus.on_suspend_room.emit(result)
	return result


static func suspend_room(room_id: String) -> Signal:
	suspend_room_async(room_id)
	return HathoraEventBus.on_suspend_room
#endregion    -- suspend_room
