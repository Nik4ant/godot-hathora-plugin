# Room V2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson
const CommonTypes = preload("res://addons/hathora_api/api/common_types.gd")
const ExposedPort = CommonTypes.ExposedPort
const RoomAllocation = CommonTypes.RoomAllocation
const Room = CommonTypes.Room

##region   -- get_connection_info
class GetConnectionInfoResponse:
	var additional_exposed_ports: Array[ExposedPort]
	var exposed_port: ExposedPort
	var status: String
	var room_id: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("status"), "ASSERT! Missing parameter \"status\" in get_connection_info response")
		self.status = data["status"]
		
		assert(data.has("roomId"), "ASSERT! Missing parameter \"roomId\" in get_connection_info response")
		self.room_id = data["roomId"]
		
		# Properties below exist only when room is ready
		if self.status == "active":
			assert(data.has("additionalExposedPorts"), "ASSERT! Missing parameter \"additionalExposedPorts\" in get_connection_info response")
			for port in data["additionalExposedPorts"]:
				self.additional_exposed_ports.push_back(
					ExposedPort.deserialize(port)
				)
			
			assert(data.has("exposedPort"), "ASSERT! Missing parameter \"exposedPort\" in get_connection_info response")
			self.exposed_port = ExposedPort.deserialize(data["exposedPort"])


## It takes some time for server to start, that's why 
## connection details may not exist at the time of the API call.
## If [param wait_until_active] is true, function will wait for [member GetConnectionInfoResponse.status] to become "active".
## ([param retry_delay] - delay between API calls in seconds)
static func get_connection_info_async(room_id: String, wait_until_active: bool = true, retry_delay: float = 1.5) -> GetConnectionInfoResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	var result: GetConnectionInfoResponse = GetConnectionInfoResponse.new()
	
	while wait_until_active and result.status != "active":
		# Note: Can't creat a timer without access to SceneTree, so...
		await Hathora.get_tree().create_timer(retry_delay).timeout
		result = await __get_connection_info_async(room_id)
		if result.error != Hathora.Error.Ok:
			break
	
	HathoraEventBus.on_get_connection_info.emit(result)
	return result


## It takes some time for server to start, that's why 
## connection details may not exist at the time of the API call.
## If [param wait_until_active] is true, function will wait for [member GetConnectionInfoResponse.status] to become "active".
## ([param retry_delay] - delay between API calls in seconds)
static func get_connection_info(room_id: String, wait_until_active: bool = true, retry_delay: float = 1.5) -> Signal:
	get_connection_info_async(room_id, wait_until_active, retry_delay)
	return HathoraEventBus.on_get_connection_info


## TODO: explain. TL;DR - this is an internal function that should never be used
static func __get_connection_info_async(room_id: String) -> GetConnectionInfoResponse:
	var result: GetConnectionInfoResponse = GetConnectionInfoResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", 
		Hathora.APP_ID, "/connectioninfo/", room_id
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json"]
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with id `" + room_id, "` exists"],
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus._internal_get_connection_info.emit(result)
	return result
#endregion -- get_connection_info


##region   -- create_room
class CreateRoomResponse:
	var additional_exposed_ports: Array[ExposedPort]
	var exposed_port: ExposedPort
	var status: String
	var room_id: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("status"), "ASSERT! Missing parameter \"status\" in create_room response")
		self.status = data["status"]
		
		assert(data.has("roomId"), "ASSERT! Missing parameter \"roomId\" in create_room response")
		self.room_id = data["roomId"]
		
		# Properties below exist only when room is ready
		if self.status == "active":
			assert(data.has("additionalExposedPorts"), "ASSERT! Missing parameter \"additionalExposedPorts\" in create_room response")
			for port in data["additionalExposedPorts"]:
				self.additional_exposed_ports.push_back(
					ExposedPort.deserialize(port)
				)
			
			assert(data.has("exposedPort"), "ASSERT! Missing parameter \"exposedPort\" in create_room response")
			self.exposed_port = ExposedPort.deserialize(data["exposedPort"])


static func create_room_async(region: String, room_config: Dictionary = {}) -> CreateRoomResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	
	var result: CreateRoomResponse = CreateRoomResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, "/create/"
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER], {
			"roomConfig": room_config,
			"region": region
		}
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.Forbidden: ["Are you trying to use a DEV_TOKEN from a different app?"]
			}, {
				Hathora.Error.MustPayFirst: "Not enough credits to create a room",
				Hathora.Error.Forbidden: "Not allowed to call `" + api_response.url + '`'
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_room.emit(result)
	return result


static func create_room(region: String, room_config: Dictionary = {}) -> Signal:
	create_room_async(region, room_config)
	return HathoraEventBus.on_create_room
#endregion -- create_room


##region   -- get_room_info
class GetRoomInfoResponse:
	var current_allocation: RoomAllocation
	var status: String
	var allocations: Array[RoomAllocation] = []
	var room_config: Dictionary
	var room_id: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("status"), "ASSERT! Missing parameter \"status\" in get_room_info response")
		self.status = data["status"]
		
		if data.has("currentAllocation"):
			self.current_allocation = RoomAllocation.deserialize(data["current_allocation"])
		
		assert(data.has("allocations"), "ASSERT! Missing parameter \"allocations\" in get_room_info response")
		for allocation in data["allocations"]:
			self.allocations.push_back(RoomAllocation.deserialize(allocation))
		
		assert(data.has("roomConfig"), "ASSERT! Missing parameter \"roomConfig\" in get_room_info response")
		self.room_config = Hathora.Http.json_parse_or(data["roomConfig"], {})
		
		assert(data.has("roomId"), "ASSERT! Missing parameter \"roomId\" in get_room_info response")
		self.room_id = data["roomId"]


static func get_room_info_async(room_id: String) -> GetRoomInfoResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: GetRoomInfoResponse = GetRoomInfoResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, "/info/", room_id
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with id `" + room_id, "` exists"],
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_room_info.emit(result)
	return result


static func get_room_info(room_id: String) -> Signal:
	get_room_info_async(room_id)
	return HathoraEventBus.on_get_room_info
#endregion -- get_room_info


##region   -- get_active_rooms_for_process
class GetActiveRoomsForProcessResponse:
	var rooms: Array[Room] = []
	
	var error
	var error_message: String
	
	func deserialize(data) -> void:
		for room_data in data:
			self.rooms.push_back(Room.deserialize(room_data)) 


static func get_active_rooms_for_process_async(process_id: String) -> GetActiveRoomsForProcessResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: GetActiveRoomsForProcessResponse = GetActiveRoomsForProcessResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, 
		"/list/", process_id, "/active"
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure process with id `" + process_id, "` exists"],
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_active_rooms_for_process.emit(result)
	return result


static func get_active_rooms_for_process(room_id: String) -> Signal:
	get_active_rooms_for_process_async(room_id)
	return HathoraEventBus.on_get_active_rooms_for_process
#endregion -- get_active_rooms_for_process


##region   -- get_active_rooms_for_process
class GetInactiveRoomsForProcessResponse:
	var rooms: Array[Room] = []
	
	var error
	var error_message: String
	
	func deserialize(data) -> void:
		for room_data in data:
			self.rooms.push_back(Room.deserialize(room_data)) 


static func get_inactive_rooms_for_process_async(process_id: String) -> GetInactiveRoomsForProcessResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: GetInactiveRoomsForProcessResponse = GetInactiveRoomsForProcessResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, 
		"/list/", process_id, "/inactive"
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure process with id `" + process_id, "` exists"],
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_inactive_rooms_for_process.emit(result)
	return result


static func get_inactive_rooms_for_process(process_id: String) -> Signal:
	get_inactive_rooms_for_process_async(process_id)
	return HathoraEventBus.on_get_inactive_rooms_for_process
#endregion -- get_inactive_rooms_for_process


##region   -- destroy_room
class DestroyRoomResponse:
	var error
	var error_message: String


static func destroy_room_async(room_id: String) -> DestroyRoomResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: DestroyRoomResponse = DestroyRoomResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, "/destroy/", room_id
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER], {}
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with room_id `" + room_id, "` exists"],
				Hathora.Error.ServerError: ["Maybe you've attempted to destroy the same room multiple times"]
			}, {
				Hathora.Error.ServerError: "Hathora servers can't destroy the room for some reason"
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_destroy_room.emit(result)
	return result


static func destroy_room(room_id: String) -> Signal:
	destroy_room_async(room_id)
	return HathoraEventBus.on_destroy_room
#endregion -- destroy_room


##region   -- suspend_room
class SuspendRoomResponse:
	var error
	var error_message: String


static func suspend_room_async(room_id: String) -> SuspendRoomResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: SuspendRoomResponse = SuspendRoomResponse.new()
	var url: String = str(
		"https://api.hathora.dev/rooms/v2/", Hathora.APP_ID, "/suspend/", room_id
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER], {}
	)
	
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with room_id `" + room_id, "` exists"],
				Hathora.Error.ServerError: ["Maybe you've attempted to suspend the same room multiple times"]
			}, {
				Hathora.Error.ServerError: "Hathora servers can't suspend the room for some reason"
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_suspend_room.emit(result)
	return result


static func suspend_room(room_id: String) -> Signal:
	suspend_room_async(room_id)
	return HathoraEventBus.on_suspend_room
#endregion -- suspend_room
