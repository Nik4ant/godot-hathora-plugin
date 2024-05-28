# Log v1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_logs_for_process
class GetLogsForProcessResponse:
	var result: String

	var error: Variant
	var error_message: String

	func deserialize(data: String) -> void:
		self.result = data


static func get_logs_for_process_async(process_id: String, follow: bool = false, tail_lines: int = 0) -> GetLogsForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetLogsForProcessResponse = GetLogsForProcessResponse.new()
	var url: String = "https://api.hathora.dev/logs/v1/{appId}/process/{processId}".format({
			"appId": Hathora.APP_ID,
			"processId": process_id,
		}
	)

	url += Hathora.Http.build_query_params({
			"follow": follow,
			"tailLines": tail_lines,
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
		# List of error codes: [400, 401, 404, 410, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_logs_for_process_v1.emit(result)
	return result


static func get_logs_for_process(process_id: String, follow: bool = false, tail_lines: int = 0) -> Signal:
	get_logs_for_process_async(process_id, follow, tail_lines)
	return HathoraEventBus.on_get_logs_for_process_v1
#endregion


#region download_log_for_process
class DownloadLogForProcessResponse:
	var result: String

	var error: Variant
	var error_message: String

	func deserialize(data: String) -> void:
		self.result = data


static func download_log_for_process_async(process_id: String) -> DownloadLogForProcessResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DownloadLogForProcessResponse = DownloadLogForProcessResponse.new()
	var url: String = "https://api.hathora.dev/logs/v1/{appId}/process/{processId}/download".format({
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
		# List of error codes: [400, 401, 404, 410]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_download_log_for_process_v1.emit(result)
	return result


static func download_log_for_process(process_id: String) -> Signal:
	download_log_for_process_async(process_id)
	return HathoraEventBus.on_download_log_for_process_v1
#endregion


