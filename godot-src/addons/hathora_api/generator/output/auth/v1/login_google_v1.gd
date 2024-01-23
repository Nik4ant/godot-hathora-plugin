# AuthV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- login_google
class LoginGoogleResponse:
	var error
	var error_message: String
	
	var token: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "Missing parameter \"token\"")
		self.token = data["token"]


static func login_google_async(id_token: String) -> LoginGoogleResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: LoginGoogleResponse = LoginGoogleResponse.new()
	var url: String = "https://api.hathora.dev/auth/v1/{appId}/login/google".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json"],
		{
			"idToken": id_token
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_login_google.emit(result)
	return result


static func login_google(id_token: String) -> Signal:
	login_google_async(id_token)
	return HathoraEventBus.on_login_google
#endregion    -- login_google
