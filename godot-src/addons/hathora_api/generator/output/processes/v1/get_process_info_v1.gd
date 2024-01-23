# ProcessesV1
const ExposedPort = preload("res://addons/hathora_api/api/common_types.gd").ExposedPort
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_process_info
class GetProcessInfoResponse:
	var error
	var error_message: String
	
	var egressed_bytes: int
	var idle_since_unix: int
	var active_connections_updated_at_unix: int
	var active_connections: int
	var rooms_allocated_updated_at_unix: int
	var rooms_allocated: int
	var room_slots_available_updated_at_unix: int
	var room_slots_available: float
	var draining: bool
	var terminated_at_unix: int
	var stopping_at_unix: int
	var started_at_unix: int
	var starting_at_unix: int
	var rooms_per_process: int
	var additional_exposed_ports: Array[ExposedPort]
	var exposed_port: ExposedPort
	var port: float
	var host: String
	var region: String
	var process_id: String
	var deployment_id: int
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("egressedBytes"), "Missing parameter \"egressedBytes\"")
		self.egressed_bytes = data["egressedBytes"]
		
		assert(data.has("idleSince"), "Missing parameter \"idleSince\"")
		self.idle_since_unix = Time.get_unix_time_from_datetime_string(data["idleSince"])
		
		assert(data.has("activeConnectionsUpdatedAt"), "Missing parameter \"activeConnectionsUpdatedAt\"")
		self.active_connections_updated_at_unix = Time.get_unix_time_from_datetime_string(data["activeConnectionsUpdatedAt"])
		
		assert(data.has("activeConnections"), "Missing parameter \"activeConnections\"")
		self.active_connections = data["activeConnections"]
		
		assert(data.has("roomsAllocatedUpdatedAt"), "Missing parameter \"roomsAllocatedUpdatedAt\"")
		self.rooms_allocated_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomsAllocatedUpdatedAt"])
		
		assert(data.has("roomsAllocated"), "Missing parameter \"roomsAllocated\"")
		self.rooms_allocated = data["roomsAllocated"]
		
		assert(data.has("roomSlotsAvailableUpdatedAt"), "Missing parameter \"roomSlotsAvailableUpdatedAt\"")
		self.room_slots_available_updated_at_unix = Time.get_unix_time_from_datetime_string(data["roomSlotsAvailableUpdatedAt"])
		
		assert(data.has("roomSlotsAvailable"), "Missing parameter \"roomSlotsAvailable\"")
		self.room_slots_available = data["roomSlotsAvailable"]
		
		assert(data.has("draining"), "Missing parameter \"draining\"")
		self.draining = data["draining"]
		
		assert(data.has("terminatedAt"), "Missing parameter \"terminatedAt\"")
		self.terminated_at_unix = Time.get_unix_time_from_datetime_string(data["terminatedAt"])
		
		assert(data.has("stoppingAt"), "Missing parameter \"stoppingAt\"")
		self.stopping_at_unix = Time.get_unix_time_from_datetime_string(data["stoppingAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		self.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("startingAt"), "Missing parameter \"startingAt\"")
		self.starting_at_unix = Time.get_unix_time_from_datetime_string(data["startingAt"])
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = data["roomsPerProcess"]
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for part in data["additionalExposedPorts"]:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(part))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("port"), "Missing parameter \"port\"")
		self.port = data["port"]
		
		assert(data.has("host"), "Missing parameter \"host\"")
		self.host = data["host"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		self.region = data["region"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		self.process_id = data["processId"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = data["deploymentId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_process_info_async(process_id: String) -> GetProcessInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetProcessInfoResponse = GetProcessInfoResponse.new()
	var url: String = "https://api.hathora.dev/processes/v1/{appId}/info/{processId}".format(
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
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_process_info.emit(result)
	return result


static func get_process_info(process_id: String) -> Signal:
	get_process_info_async(process_id)
	return HathoraEventBus.on_get_process_info
#endregion    -- get_process_info
