# Auth V1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson

##region     -- login_anonymous
class LoginAnonymousResponse:
	var auth_token: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in anonymous auth")
		self.auth_token = data["token"]


static func login_anonymous_async() -> LoginAnonymousResponse:
	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", Hathora.APP_ID, "/login/anonymous")
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json"], {}
	)
	# Api errors
	result.error = api_response.error	
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(api_response)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_login_anonymous.emit(result)
	return result


static func login_anonymous() -> Signal:
	login_anonymous_async()
	return HathoraEventBus.on_login_anonymous
##endregion  -- login_anonymous


##region     -- login_nickname
class LoginNicknameResponse:
	var auth_token: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in nickname auth")
		self.auth_token = data["token"]


static func login_nickname_async(nickname: String) -> LoginNicknameResponse:
	var result: LoginNicknameResponse = LoginNicknameResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", Hathora.APP_ID, "/login/nickname")
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json"], {
			"nickname": nickname
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(api_response)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_login_nickname.emit(result)
	return result


static func login_nickname(nickname: String) -> Signal:
	login_nickname_async(nickname)
	return HathoraEventBus.on_login_nickname
##endregion  -- login_nickname


##region     -- login_google
class LoginGoogleResponse:
	var auth_token: String
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in google auth")
		self.auth_token = data["token"]


static func login_google_async(id_token: String) -> LoginGoogleResponse:
	var result: LoginGoogleResponse = LoginGoogleResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", Hathora.APP_ID, "/login/google")
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json"], {
			"idToken": id_token
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.Unauthorized: ["Make sure your Google-signed OIDC ID token is valid"]
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_login_google.emit(result)
	return result


static func login_google(id_token: String) -> Signal:
	login_google_async(id_token)
	return HathoraEventBus.on_login_google
##endregion  -- login_google
