# BuildV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- create_build
class CreateBuildResponse:
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


func create_build_async(build_tag: String = '') -> CreateBuildResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateBuildResponse = CreateBuildResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/create".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"buildTag": build_tag
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_build.emit(result)
	return result


func create_build(build_tag: String = '') -> Signal:
	create_build_async(build_tag)
	return HathoraEventBus.on_create_build
##endregion    -- create_build
