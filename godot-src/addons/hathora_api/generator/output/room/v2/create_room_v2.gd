# RoomV2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- create_room
class CreateRoomResponse:
	var error
	var error_message: String
	
	var additional_exposed_ports: Array[ExposedPort]
	var exposed_port: ExposedPort
	var status: String
	var room_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for part in data:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(part))

		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]


func create_room_async(region: String, room_id: String = '', room_config: String = '') -> CreateRoomResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	
	var result: CreateRoomResponse = CreateRoomResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/create".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"roomId": room_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"roomConfig": room_config,
			"region": region
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [400, 402, 403, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_room.emit(result)
	return result


func create_room(region: String, room_config: String = '', room_id: String = '') -> Signal:
	create_room_async(region, room_config, room_id)
	return HathoraEventBus.on_create_room
##endregion    -- create_room
