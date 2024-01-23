# AppV1
const AuthConfiguration = preload("res://addons/hathora_api/api/common_types.gd").AuthConfiguration
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- create_app
class CreateAppResponse:
	var error
	var error_message: String
	
	var deleted_by: String
	var deleted_at_unix: int
	var created_at_unix: int
	var created_by: String
	var org_id: String
	var auth_configuration: AuthConfiguration
	var app_secret: String
	var app_id: String
	var app_name: String
	
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
			"appName": app_name
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [422, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_app.emit(result)
	return result


static func create_app(auth_configuration: Dictionary, app_name: String) -> Signal:
	create_app_async(auth_configuration, app_name)
	return HathoraEventBus.on_create_app
#endregion    -- create_app