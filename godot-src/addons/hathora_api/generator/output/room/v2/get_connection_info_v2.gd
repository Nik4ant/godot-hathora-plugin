# RoomV2
const ExposedPort = preload("res://addons/hathora_api/api/common_types.gd").ExposedPort
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_connection_info
class GetConnectionInfoResponse:
	var error
	var error_message: String
	
	var additional_exposed_ports: Array[ExposedPort]
	var exposed_port: ExposedPort
	var status: String
	var room_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for part in data["additionalExposedPorts"]:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(part))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]


static func get_connection_info_async(room_id: String) -> GetConnectionInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetConnectionInfoResponse = GetConnectionInfoResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/connectioninfo/{roomId}".format(
		{
			"appId": Hathora.APP_ID,
			"roomId": room_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json"]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [400, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_connection_info.emit(result)
	return result


static func get_connection_info(room_id: String) -> Signal:
	get_connection_info_async(room_id)
	return HathoraEventBus.on_get_connection_info
#endregion    -- get_connection_info
