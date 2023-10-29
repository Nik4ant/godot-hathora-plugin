# RoomV2
const RoomAllocation = preload("res://addons/hathora_api/api/common_types.gd").RoomAllocation
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_room_info
class GetRoomInfoResponse:
	var error
	var error_message: String
	
	var current_allocation: RoomAllocation
	var status: String
	var allocations: Array[RoomAllocation]
	var room_config: String
	var room_id: String
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("currentAllocation"), "Missing parameter \"currentAllocation\"")
		self.current_allocation = RoomAllocation.deserialize(data["currentAllocation"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("allocations"), "Missing parameter \"allocations\"")
		for part in data:
			self.allocations.push_back(RoomAllocation.deserialize(part))

		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		self.room_config = data["roomConfig"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


func get_room_info_async(room_id: String) -> GetRoomInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetRoomInfoResponse = GetRoomInfoResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/info/{roomId}".format(
		{
			"appId": Hathora.APP_ID,
			"roomId": room_id
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
	
	HathoraEventBus.on_get_room_info.emit(result)
	return result


func get_room_info(room_id: String) -> Signal:
	get_room_info_async(room_id)
	return HathoraEventBus.on_get_room_info
##endregion    -- get_room_info
