# RoomV2
const RoomWithoutAllocations = preload("res://addons/hathora_api/api/common_types.gd").RoomWithoutAllocations
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_active_rooms_for_process
class GetActiveRoomsForProcessResponse:
	var error
	var error_message: String
	
	var result: Array[RoomWithoutAllocations]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(RoomWithoutAllocations.deserialize(part))


func get_active_rooms_for_process_async(process_id: String) -> GetActiveRoomsForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetActiveRoomsForProcessResponse = GetActiveRoomsForProcessResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/list/{processId}/active".format(
		{
			"appId": Hathora.APP_ID,
			"processId": process_id
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
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_active_rooms_for_process.emit(result)
	return result


func get_active_rooms_for_process(process_id: String) -> Signal:
	get_active_rooms_for_process_async(process_id)
	return HathoraEventBus.on_get_active_rooms_for_process
##endregion    -- get_active_rooms_for_process
