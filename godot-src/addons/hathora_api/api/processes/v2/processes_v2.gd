# Processes v2
const ProcessV2 = preload("res://addons/hathora_api/api/common_types.gd").ProcessV2
const ExposedPort = preload("res://addons/hathora_api/api/common_types.gd").ExposedPort
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_process_info
class GetProcessInfoResponse:
	var status: String
	## Tracks the number of rooms that have been allocated to the process.
	var rooms_allocated: int
	## When the process has been terminated.
	var terminated_at_unix: int
	## When the process is issued to stop. We use this to determine when we should stop billing.
	var stopping_at_unix: int
	## When the process bound to the specified port. We use this to determine when we should start billing.
	var started_at_unix: int
	## When the process started being provisioned.
	var created_at_unix: int
	## Governs how many [rooms](https://hathora.dev/docs/concepts/hathora-entities#room) can be scheduled in a process.
	var rooms_per_process: int
	var additional_exposed_ports: Array[ExposedPort]
	## Connection details for an active process.
	var exposed_port: ExposedPort
	var region: String
	## System generated unique identifier to a runtime instance of your game server.
	var process_id: String
	## System generated id for a deployment. Increments by 1.
	var deployment_id: int
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("roomsAllocated"), "Missing parameter \"roomsAllocated\"")
		self.rooms_allocated = int(data["roomsAllocated"])
		
		assert(data.has("terminatedAt"), "Missing parameter \"terminatedAt\"")
		self.terminated_at_unix = Time.get_unix_time_from_datetime_string(data["terminatedAt"])
		
		assert(data.has("stoppingAt"), "Missing parameter \"stoppingAt\"")
		self.stopping_at_unix = Time.get_unix_time_from_datetime_string(data["stoppingAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		self.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("roomsPerProcess"), "Missing parameter \"roomsPerProcess\"")
		self.rooms_per_process = int(data["roomsPerProcess"])
		
		assert(data.has("additionalExposedPorts"), "Missing parameter \"additionalExposedPorts\"")
		for item: Dictionary in data["additionalExposedPorts"]:
			self.additional_exposed_ports.push_back(ExposedPort.deserialize(item))
		
		assert(data.has("exposedPort"), "Missing parameter \"exposedPort\"")
		self.exposed_port = ExposedPort.deserialize(data["exposedPort"])
		
		assert(data.has("region"), "Missing parameter \"region\"")
		self.region = data["region"]
		
		assert(data.has("processId"), "Missing parameter \"processId\"")
		self.process_id = data["processId"]
		
		assert(data.has("deploymentId"), "Missing parameter \"deploymentId\"")
		self.deployment_id = int(data["deploymentId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_process_info_async(process_id: String) -> GetProcessInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetProcessInfoResponse = GetProcessInfoResponse.new()
	var url: String = "https://api.hathora.dev/processes/v2/{appId}/info/{processId}".format({
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
	
	HathoraEventBus.on_get_process_info_v2.emit(result)
	return result


static func get_process_info(process_id: String) -> Signal:
	get_process_info_async(process_id)
	return HathoraEventBus.on_get_process_info_v2
#endregion


#region get_latest_processes
class GetLatestProcessesResponse:
	var result: Array[ProcessV2]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(ProcessV2.deserialize(item))


static func get_latest_processes_async(status: Array[Dictionary] = [], region: Array[Dictionary] = []) -> GetLatestProcessesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	
	var result: GetLatestProcessesResponse = GetLatestProcessesResponse.new()
	var url: String = "https://api.hathora.dev/processes/v2/{appId}/list/latest".format({
			"appId": Hathora.APP_ID,
		}
	)

	url += Hathora.Http.build_query_params({
			"status": status,
			"region": region,
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
	
	HathoraEventBus.on_get_latest_processes_v2.emit(result)
	return result


static func get_latest_processes(status: Array[Dictionary] = [], region: Array[Dictionary] = []) -> Signal:
	get_latest_processes_async(status, region)
	return HathoraEventBus.on_get_latest_processes_v2
#endregion


#region stop_process
## No content
class StopProcessResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func stop_process_async(process_id: String) -> StopProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: StopProcessResponse = StopProcessResponse.new()
	var url: String = "https://api.hathora.dev/processes/v2/{appId}/stop/{processId}".format({
			"appId": Hathora.APP_ID,
			"processId": process_id,
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
	
	HathoraEventBus.on_stop_process_v2.emit(result)
	return result


static func stop_process(process_id: String) -> Signal:
	stop_process_async(process_id)
	return HathoraEventBus.on_stop_process_v2
#endregion


