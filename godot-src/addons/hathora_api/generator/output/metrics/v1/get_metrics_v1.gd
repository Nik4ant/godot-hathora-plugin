# MetricsV1
const MetricValue = preload("res://addons/hathora_api/api/common_types.gd").MetricValue
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_metrics
class GetMetricsResponse:
	var error
	var error_message: String
	
	var cpu: Array[MetricValue]
	var memory: Array[MetricValue]
	var rate_egress: Array[MetricValue]
	var total_egress: Array[MetricValue]
	var active_connections: Array[MetricValue]
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("cpu"), "Missing parameter \"cpu\"")
		for part in data["cpu"]:
			self.cpu.push_back(MetricValue.deserialize(part))
		
		assert(data.has("memory"), "Missing parameter \"memory\"")
		for part in data["memory"]:
			self.memory.push_back(MetricValue.deserialize(part))
		
		assert(data.has("rate_egress"), "Missing parameter \"rate_egress\"")
		for part in data["rate_egress"]:
			self.rate_egress.push_back(MetricValue.deserialize(part))
		
		assert(data.has("total_egress"), "Missing parameter \"total_egress\"")
		for part in data["total_egress"]:
			self.total_egress.push_back(MetricValue.deserialize(part))
		
		assert(data.has("active_connections"), "Missing parameter \"active_connections\"")
		for part in data["active_connections"]:
			self.active_connections.push_back(MetricValue.deserialize(part))


static func get_metrics_async(process_id: String, step: int = 0, start: float = 0.0, end: float = 0.0, metrics: Array[String] = []) -> GetMetricsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetMetricsResponse = GetMetricsResponse.new()
	var url: String = "https://api.hathora.dev/metrics/v1/{appId}/process/{processId}".format(
		{
			"appId": Hathora.APP_ID,
			"processId": process_id
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"metrics": metrics,
			"end": end,
			"start": start,
			"step": step
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
		# List of error codes: [404, 422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_metrics.emit(result)
	return result


static func get_metrics(process_id: String, step: int = 0, start: float = 0.0, end: float = 0.0, metrics: Array[String] = []) -> Signal:
	get_metrics_async(process_id, step, start, end, metrics)
	return HathoraEventBus.on_get_metrics
#endregion    -- get_metrics
