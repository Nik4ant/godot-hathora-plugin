# ProcessesV1
const Process = preload("res://addons/hathora_api/api/common_types.gd").Process
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_stopped_processes
class GetStoppedProcessesResponse:
	var error
	var error_message: String
	
	var result: Array[Process]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(Process.deserialize(part))


func get_stopped_processes_async(region: String = '') -> GetStoppedProcessesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	
	var result: GetStoppedProcessesResponse = GetStoppedProcessesResponse.new()
	var url: String = "https://api.hathora.dev/processes/v1/{appId}/list/stopped".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"region": region
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
	
	HathoraEventBus.on_get_stopped_processes.emit(result)
	return result


func get_stopped_processes(region: String = '') -> Signal:
	get_stopped_processes_async(region)
	return HathoraEventBus.on_get_stopped_processes
##endregion    -- get_stopped_processes
