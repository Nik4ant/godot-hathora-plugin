# Build v1
const Build = preload("res://addons/hathora_api/api/common_types.gd").Build
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_builds
class GetBuildsResponse:
	var result: Array[Build]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(Build.deserialize(item))


static func get_builds_async() -> GetBuildsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBuildsResponse = GetBuildsResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/list".format({
			"appId": Hathora.APP_ID,
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
	
	HathoraEventBus.on_get_builds_v1.emit(result)
	return result


static func get_builds() -> Signal:
	get_builds_async()
	return HathoraEventBus.on_get_builds_v1
#endregion


#region get_build_info
## A build represents a game server artifact and its associated metadata.
class GetBuildInfoResponse:
	## Tag to associate an external version with a build. It is accessible via [`GetBuildInfo()`](https://hathora.dev/api#tag/BuildV1/operation/GetBuildInfo).
	var build_tag: String
	var regional_container_tags: Array[Dictionary]
	## The size (in bytes) of the Docker image built by Hathora.
	var image_size: int
	## Current status of your build.
	## `created`: a build was created but not yet run
	## `running`: the build process is actively executing
	## `succeeded`: the game server artifact was successfully built and stored in the Hathora registries
	## `failed`: the build process was unsuccessful, most likely due to an error with the `Dockerfile`
	var status: String
	## When the build was deleted.
	var deleted_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) finished executing.
	var finished_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) is called.
	var started_at_unix: int
	## When [`CreateBuild()`](https://hathora.dev/api#tag/BuildV1/operation/CreateBuild) is called.
	var created_at_unix: int
	## UserId or email address for the user that created the build.
	var created_by: String
	## System generated id for a build. Increments by 1.
	var build_id: int
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("buildTag"), "Missing parameter \"buildTag\"")
		self.build_tag = data["buildTag"]
		
		assert(data.has("regionalContainerTags"), "Missing parameter \"regionalContainerTags\"")
		for item: Dictionary in data["regionalContainerTags"]:
			self.regional_container_tags.push_back(item)
		
		assert(data.has("imageSize"), "Missing parameter \"imageSize\"")
		self.image_size = int(data["imageSize"])
		
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
		self.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func get_build_info_async(build_id: int) -> GetBuildInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBuildInfoResponse = GetBuildInfoResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/info/{buildId}".format({
			"appId": Hathora.APP_ID,
			"buildId": build_id,
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
	
	HathoraEventBus.on_get_build_info_v1.emit(result)
	return result


static func get_build_info(build_id: int) -> Signal:
	get_build_info_async(build_id)
	return HathoraEventBus.on_get_build_info_v1
#endregion


#region create_build
## A build represents a game server artifact and its associated metadata.
class CreateBuildResponse:
	## Tag to associate an external version with a build. It is accessible via [`GetBuildInfo()`](https://hathora.dev/api#tag/BuildV1/operation/GetBuildInfo).
	var build_tag: String
	var regional_container_tags: Array[Dictionary]
	## The size (in bytes) of the Docker image built by Hathora.
	var image_size: int
	## Current status of your build.
	## `created`: a build was created but not yet run
	## `running`: the build process is actively executing
	## `succeeded`: the game server artifact was successfully built and stored in the Hathora registries
	## `failed`: the build process was unsuccessful, most likely due to an error with the `Dockerfile`
	var status: String
	## When the build was deleted.
	var deleted_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) finished executing.
	var finished_at_unix: int
	## When [`RunBuild()`](https://hathora.dev/api#tag/BuildV1/operation/RunBuild) is called.
	var started_at_unix: int
	## When [`CreateBuild()`](https://hathora.dev/api#tag/BuildV1/operation/CreateBuild) is called.
	var created_at_unix: int
	## UserId or email address for the user that created the build.
	var created_by: String
	## System generated id for a build. Increments by 1.
	var build_id: int
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("buildTag"), "Missing parameter \"buildTag\"")
		self.build_tag = data["buildTag"]
		
		assert(data.has("regionalContainerTags"), "Missing parameter \"regionalContainerTags\"")
		for item: Dictionary in data["regionalContainerTags"]:
			self.regional_container_tags.push_back(item)
		
		assert(data.has("imageSize"), "Missing parameter \"imageSize\"")
		self.image_size = int(data["imageSize"])
		
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
		self.build_id = int(data["buildId"])
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


static func create_build_async(build_tag: String = '') -> CreateBuildResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateBuildResponse = CreateBuildResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/create".format({
			"appId": Hathora.APP_ID,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"buildTag": build_tag,
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
	
	HathoraEventBus.on_create_build_v1.emit(result)
	return result


static func create_build(build_tag: String = '') -> Signal:
	create_build_async(build_tag)
	return HathoraEventBus.on_create_build_v1
#endregion


#region delete_build
## No content
class DeleteBuildResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func delete_build_async(build_id: int) -> DeleteBuildResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DeleteBuildResponse = DeleteBuildResponse.new()
	var url: String = "https://api.hathora.dev/builds/v1/{appId}/delete/{buildId}".format({
			"appId": Hathora.APP_ID,
			"buildId": build_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.delete_async(
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
	
	HathoraEventBus.on_delete_build_v1.emit(result)
	return result


static func delete_build(build_id: int) -> Signal:
	delete_build_async(build_id)
	return HathoraEventBus.on_delete_build_v1
#endregion


