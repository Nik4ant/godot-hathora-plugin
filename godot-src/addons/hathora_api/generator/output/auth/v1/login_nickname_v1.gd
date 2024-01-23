# AuthV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- login_nickname
class LoginNicknameResponse:
	var error
	var error_message: String
	
	var token: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "Missing parameter \"token\"")
		self.token = data["token"]


static func login_nickname_async(nickname: String) -> LoginNicknameResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: LoginNicknameResponse = LoginNicknameResponse.new()
	var url: String = "https://api.hathora.dev/auth/v1/{appId}/login/nickname".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json"],
		{
			"nickname": nickname
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_login_nickname.emit(result)
	return result


static func login_nickname(nickname: String) -> Signal:
	login_nickname_async(nickname)
	return HathoraEventBus.on_login_nickname
#endregion    -- login_nickname
