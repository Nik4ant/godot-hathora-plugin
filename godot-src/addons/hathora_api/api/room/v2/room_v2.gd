# Room v2
const RoomWithoutAllocations = preload("res://addons/hathora_api/api/common_types.gd").RoomWithoutAllocations
const RoomAllocation = preload("res://addons/hathora_api/api/common_types.gd").RoomAllocation
const ExposedPort = preload("res://addons/hathora_api/api/common_types.gd").ExposedPort
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region create_room
## Connection information for the default and additional ports.
class CreateRoomResponse:
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	## (optional)
	var exposed_port: ExposedPort = null
	## `exposedPort` will only be available when the `status` of a room is "active".
	var status: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		if data.has("exposedPort"):
			self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		self.process_id = data["processId"]


static func create_room_async(region: String, room_config: String = '', room_id: String = '') -> CreateRoomResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	
	var result: CreateRoomResponse = CreateRoomResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/create".format({
			"appId": Hathora.APP_ID,
		}
	)

	url += Hathora.Http.build_query_params({
			"roomId": room_id,
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"roomConfig": room_config,
			"region": region,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [400, 401, 402, 403, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_room_v2.emit(result)
	return result


static func create_room(region: String, room_config: String = '', room_id: String = '') -> Signal:
	create_room_async(region, room_config, room_id)
	return HathoraEventBus.on_create_room_v2
#endregion


#region get_room_info
## A room object represents a game session or match.
class GetRoomInfoResponse:
	## Metadata on an allocated instance of a room.
	var current_allocation: RoomAllocation
	## The allocation status of a room.
	## `scheduling`: a process is not allocated yet and the room is waiting to be scheduled
	## `active`: ready to accept connections
	## `suspended`: room is unallocated from the process but can be rescheduled later with the same `roomId`
	## `destroyed`: all associated metadata is deleted
	var status: String
	var allocations: Array[RoomAllocation]
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("currentAllocation"), "Missing parameter \"currentAllocation\"")
		self.current_allocation = RoomAllocation.deserialize(data["currentAllocation"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("allocations"), "Missing parameter \"allocations\"")
		for item: Dictionary in data["allocations"]:
			self.allocations.push_back(RoomAllocation.deserialize(item))
		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		self.room_config = data["roomConfig"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_room_info_async(room_id: String) -> GetRoomInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetRoomInfoResponse = GetRoomInfoResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/info/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_room_info_v2.emit(result)
	return result


static func get_room_info(room_id: String) -> Signal:
	get_room_info_async(room_id)
	return HathoraEventBus.on_get_room_info_v2
#endregion


#region get_active_rooms_for_process
class GetActiveRoomsForProcessResponse:
	var result: Array[RoomWithoutAllocations]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(RoomWithoutAllocations.deserialize(item))


static func get_active_rooms_for_process_async(process_id: String) -> GetActiveRoomsForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetActiveRoomsForProcessResponse = GetActiveRoomsForProcessResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/list/{processId}/active".format({
			"appId": Hathora.APP_ID,
			"processId": process_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_active_rooms_for_process_v2.emit(result)
	return result


static func get_active_rooms_for_process(process_id: String) -> Signal:
	get_active_rooms_for_process_async(process_id)
	return HathoraEventBus.on_get_active_rooms_for_process_v2
#endregion


#region get_inactive_rooms_for_process
class GetInactiveRoomsForProcessResponse:
	var result: Array[RoomWithoutAllocations]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(RoomWithoutAllocations.deserialize(item))


static func get_inactive_rooms_for_process_async(process_id: String) -> GetInactiveRoomsForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetInactiveRoomsForProcessResponse = GetInactiveRoomsForProcessResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/list/{processId}/inactive".format({
			"appId": Hathora.APP_ID,
			"processId": process_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_inactive_rooms_for_process_v2.emit(result)
	return result


static func get_inactive_rooms_for_process(process_id: String) -> Signal:
	get_inactive_rooms_for_process_async(process_id)
	return HathoraEventBus.on_get_inactive_rooms_for_process_v2
#endregion


#region destroy_room
## No content
class DestroyRoomResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func destroy_room_async(room_id: String) -> DestroyRoomResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DestroyRoomResponse = DestroyRoomResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/destroy/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		[Hathora.DEV_AUTH_HEADER],
		{
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_destroy_room_v2.emit(result)
	return result


static func destroy_room(room_id: String) -> Signal:
	destroy_room_async(room_id)
	return HathoraEventBus.on_destroy_room_v2
#endregion


#region suspend_room
## No content
class SuspendRoomResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func suspend_room_async(room_id: String) -> SuspendRoomResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: SuspendRoomResponse = SuspendRoomResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/suspend/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		[Hathora.DEV_AUTH_HEADER],
		{
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_suspend_room_v2.emit(result)
	return result


static func suspend_room(room_id: String) -> Signal:
	suspend_room_async(room_id)
	return HathoraEventBus.on_suspend_room_v2
#endregion


#region get_connection_info
## Connection information for the default and additional ports.
class GetConnectionInfoResponse:
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	## (optional)
	var exposed_port: ExposedPort = null
	## `exposedPort` will only be available when the `status` of a room is "active".
	var status: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		if data.has("exposedPort"):
			self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]


static func get_connection_info_async(room_id: String) -> GetConnectionInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetConnectionInfoResponse = GetConnectionInfoResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/connectioninfo/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [400, 402, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_connection_info_v2.emit(result)
	return result


static func get_connection_info(room_id: String) -> Signal:
	get_connection_info_async(room_id)
	return HathoraEventBus.on_get_connection_info_v2
#endregion


#region update_room_config
## No content
class UpdateRoomConfigResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func update_room_config_async(room_config: String, room_id: String) -> UpdateRoomConfigResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: UpdateRoomConfigResponse = UpdateRoomConfigResponse.new()
	var url: String = "https://api.hathora.dev/rooms/v2/{appId}/update/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"roomConfig": room_config,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_update_room_config_v2.emit(result)
	return result


static func update_room_config(room_config: String, room_id: String) -> Signal:
	update_room_config_async(room_config, room_id)
	return HathoraEventBus.on_update_room_config_v2
#endregion


