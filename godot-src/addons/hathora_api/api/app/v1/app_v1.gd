# App v1
const AuthConfiguration = preload("res://addons/hathora_api/api/common_types.gd").AuthConfiguration
const ApplicationWithDeployment = preload("res://addons/hathora_api/api/common_types.gd").ApplicationWithDeployment
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_apps
class GetAppsResponse:
	var result: Array[ApplicationWithDeployment]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(ApplicationWithDeployment.deserialize(item))


static func get_apps_async() -> GetAppsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetAppsResponse = GetAppsResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/list"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_apps_v1.emit(result)
	return result


static func get_apps() -> Signal:
	get_apps_async()
	return HathoraEventBus.on_get_apps_v1
#endregion


#region create_app
## An application object is the top level namespace for the game server.
class CreateAppResponse:
	## UserId or email address for the user that deleted the application.
	var deleted_by: String
	## When the application was deleted.
	var deleted_at_unix: int
	## When the application was created.
	var created_at_unix: int
	## UserId or email address for the user that created the application.
	var created_by: String
	## System generated unique identifier for an organization. Not guaranteed to have a specific format.
	var org_id: String
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Secret that is used for identity and access management.
	var app_secret: String
	## System generated unique identifier for an application.
	var app_id: String
	## Readable name for an application. Must be unique within an organization.
	var app_name: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("deletedBy"), "Missing parameter \"deletedBy\"")
		self.deleted_by = data["deletedBy"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		self.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		self.org_id = data["orgId"]
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		self.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appSecret"), "Missing parameter \"appSecret\"")
		self.app_secret = data["appSecret"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		self.app_name = data["appName"]


static func create_app_async(auth_configuration: Dictionary, app_name: String) -> CreateAppResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateAppResponse = CreateAppResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/create"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"authConfiguration": auth_configuration,
			"appName": app_name,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_app_v1.emit(result)
	return result


static func create_app(auth_configuration: Dictionary, app_name: String) -> Signal:
	create_app_async(auth_configuration, app_name)
	return HathoraEventBus.on_create_app_v1
#endregion


#region update_app
## An application object is the top level namespace for the game server.
class UpdateAppResponse:
	## UserId or email address for the user that deleted the application.
	var deleted_by: String
	## When the application was deleted.
	var deleted_at_unix: int
	## When the application was created.
	var created_at_unix: int
	## UserId or email address for the user that created the application.
	var created_by: String
	## System generated unique identifier for an organization. Not guaranteed to have a specific format.
	var org_id: String
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Secret that is used for identity and access management.
	var app_secret: String
	## System generated unique identifier for an application.
	var app_id: String
	## Readable name for an application. Must be unique within an organization.
	var app_name: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("deletedBy"), "Missing parameter \"deletedBy\"")
		self.deleted_by = data["deletedBy"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		self.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		self.org_id = data["orgId"]
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		self.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appSecret"), "Missing parameter \"appSecret\"")
		self.app_secret = data["appSecret"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		self.app_name = data["appName"]


static func update_app_async(auth_configuration: Dictionary, app_name: String) -> UpdateAppResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: UpdateAppResponse = UpdateAppResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/update/{appId}".format({
			"appId": Hathora.APP_ID,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"authConfiguration": auth_configuration,
			"appName": app_name,
		}
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
	
	HathoraEventBus.on_update_app_v1.emit(result)
	return result


static func update_app(auth_configuration: Dictionary, app_name: String) -> Signal:
	update_app_async(auth_configuration, app_name)
	return HathoraEventBus.on_update_app_v1
#endregion


#region get_app_info
## An application object is the top level namespace for the game server.
class GetAppInfoResponse:
	## UserId or email address for the user that deleted the application.
	var deleted_by: String
	## When the application was deleted.
	var deleted_at_unix: int
	## When the application was created.
	var created_at_unix: int
	## UserId or email address for the user that created the application.
	var created_by: String
	## System generated unique identifier for an organization. Not guaranteed to have a specific format.
	var org_id: String
	## Configure [player authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service) for your application. Use Hathora's built-in auth providers or use your own [custom authentication](https://hathora.dev/docs/lobbies-and-matchmaking/auth-service#custom-auth-provider).
	var auth_configuration: AuthConfiguration
	## Secret that is used for identity and access management.
	var app_secret: String
	## System generated unique identifier for an application.
	var app_id: String
	## Readable name for an application. Must be unique within an organization.
	var app_name: String

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("deletedBy"), "Missing parameter \"deletedBy\"")
		self.deleted_by = data["deletedBy"]
		
		assert(data.has("deletedAt"), "Missing parameter \"deletedAt\"")
		self.deleted_at_unix = Time.get_unix_time_from_datetime_string(data["deletedAt"])
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("orgId"), "Missing parameter \"orgId\"")
		self.org_id = data["orgId"]
		
		assert(data.has("authConfiguration"), "Missing parameter \"authConfiguration\"")
		self.auth_configuration = AuthConfiguration.deserialize(data["authConfiguration"])
		
		assert(data.has("appSecret"), "Missing parameter \"appSecret\"")
		self.app_secret = data["appSecret"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]
		
		assert(data.has("appName"), "Missing parameter \"appName\"")
		self.app_name = data["appName"]


static func get_app_info_async() -> GetAppInfoResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetAppInfoResponse = GetAppInfoResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/info/{appId}".format({
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
	
	HathoraEventBus.on_get_app_info_v1.emit(result)
	return result


static func get_app_info() -> Signal:
	get_app_info_async()
	return HathoraEventBus.on_get_app_info_v1
#endregion


#region delete_app
## No content
class DeleteAppResponse:
	var result: Dictionary

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		self.result = data


static func delete_app_async() -> DeleteAppResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: DeleteAppResponse = DeleteAppResponse.new()
	var url: String = "https://api.hathora.dev/apps/v1/delete/{appId}".format({
			"appId": Hathora.APP_ID,
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
		# List of error codes: [401, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_delete_app_v1.emit(result)
	return result


static func delete_app() -> Signal:
	delete_app_async()
	return HathoraEventBus.on_delete_app_v1
#endregion


