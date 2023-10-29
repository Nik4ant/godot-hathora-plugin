# BuildV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_build_info
class GetBuildInfoResponse:
	var error
	var error_message: String
	
	var build_tag: String
	var regional_container_tags: Array[Dictionary]
	var image_size: float
	var status: String
	var deleted_at_unix: int
	var finished_at_unix: int
	var started_at_unix: int
	var created_at_unix: int
	var created_by: String
	var build_id: int
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("buildTag"), "Missing parameter \"buildTag\"")
		self.build_tag = data["buildTag"]
		
		assert(data.has("regionalContainerTags"), "Missing parameter \"regionalContainerTags\"")
		for part in data:
			self.regional_container_tags.push_back(part)

		
		assert(data.has("imageSize"), "Missing parameter \"imageSize\"")
		self.image_size = data["imageSize"]
		
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		self.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("finishedAt"), "Missing parameter \"finishedAt\"")
		self.finished_at_unix = Time.get_unix_time_from_datetime_string(data["finishedAt"])
		
		assert(data.has("startedAt"), "Missing parameter \"startedAt\"")
		self.started_at_unix = Time.get_unix_time_from_datetime_string(data["startedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("buildId"), "Missing parameter \"buildId\"")
		self.build_id = data["buildId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


func get_build_info_async(build_id: int) -> GetBuildInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBuildInfoResponse = GetBuildInfoResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/info/{buildId}".format(
		{
			"appId": Hathora.APP_ID,
			"buildId": build_id
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
	
	HathoraEventBus.on_get_build_info.emit(result)
	return result


func get_build_info(build_id: int) -> Signal:
	get_build_info_async(build_id)
	return HathoraEventBus.on_get_build_info
##endregion    -- get_build_info
