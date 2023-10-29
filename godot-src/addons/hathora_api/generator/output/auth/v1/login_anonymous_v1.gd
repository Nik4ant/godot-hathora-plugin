# AuthV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- login_anonymous
class LoginAnonymousResponse:
	var error
	var error_message: String
	
	var token: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "Missing parameter \"token\"")
		self.token = data["token"]


func login_anonymous_async() -> LoginAnonymousResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
	var url: String = "https://api.hathora.dev/auth/v1/{appId}/login/anonymous".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json"]
	, {}

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
	
	HathoraEventBus.on_login_anonymous.emit(result)
	return result


func login_anonymous() -> Signal:
	login_anonymous_async()
	return HathoraEventBus.on_login_anonymous
##endregion    -- login_anonymous
