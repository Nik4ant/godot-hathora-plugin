# LogV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_logs_for_process
class GetLogsForProcessResponse:
	var error
	var error_message: String
	
	var result: String
	
	func deserialize(data: String) -> void:
		self.result = data


static func get_logs_for_process_async(process_id: String, tail_lines: int = 0, follow: bool = false) -> GetLogsForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetLogsForProcessResponse = GetLogsForProcessResponse.new()
	var url: String = "https://api.hathora.dev/logs/v1/{appId}/process/{processId}".format(
		{
			"appId": Hathora.APP_ID,
			"processId": process_id
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"follow": follow,
			"tailLines": tail_lines
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
		# List of error codes: [400, 404, 410, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_logs_for_process.emit(result)
	return result


static func get_logs_for_process(process_id: String, tail_lines: int = 0, follow: bool = false) -> Signal:
	get_logs_for_process_async(process_id, tail_lines, follow)
	return HathoraEventBus.on_get_logs_for_process
#endregion    -- get_logs_for_process
