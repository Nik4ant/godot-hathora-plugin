# Metrics v1
const MetricValue = preload("res://addons/hathora_api/api/common_types.gd").MetricValue
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_metrics
## Construct a type with a set of properties K of type T
class GetMetricsResponse:
	## (optional)
	var cpu: Array[MetricValue] = []
	## (optional)
	var memory: Array[MetricValue] = []
	## (optional)
	var rate_egress: Array[MetricValue] = []
	## (optional)
	var total_egress: Array[MetricValue] = []
	## (optional)
	var active_connections: Array[MetricValue] = []

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		if data.has("cpu"):
			for item: Dictionary in data["cpu"]:
				self.cpu.push_back(MetricValue.deserialize(item))
		
		if data.has("memory"):
			for item: Dictionary in data["memory"]:
				self.memory.push_back(MetricValue.deserialize(item))
		
		if data.has("rateEgress"):
			for item: Dictionary in data["rateEgress"]:
				self.rate_egress.push_back(MetricValue.deserialize(item))
		
		if data.has("totalEgress"):
			for item: Dictionary in data["totalEgress"]:
				self.total_egress.push_back(MetricValue.deserialize(item))
		
		if data.has("activeConnections"):
			for item: Dictionary in data["activeConnections"]:
				self.active_connections.push_back(MetricValue.deserialize(item))


static func get_metrics_async(process_id: String, metrics: Array[Dictionary] = [], end: float = 0.0, start: float = 0.0, step: int = 0) -> GetMetricsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetMetricsResponse = GetMetricsResponse.new()
	var url: String = "https://api.hathora.dev/metrics/v1/{appId}/process/{processId}".format({
			"appId": Hathora.APP_ID,
			"processId": process_id,
		}
	)

	url += Hathora.Http.build_query_params({
			"metrics": metrics,
			"end": end,
			"start": start,
			"step": step,
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
		# List of error codes: [401, 404, 422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_metrics_v1.emit(result)
	return result


static func get_metrics(process_id: String, metrics: Array[Dictionary] = [], end: float = 0.0, start: float = 0.0, step: int = 0) -> Signal:
	get_metrics_async(process_id, metrics, end, start, step)
	return HathoraEventBus.on_get_metrics_v1
#endregion


