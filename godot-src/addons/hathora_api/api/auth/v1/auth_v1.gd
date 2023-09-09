# Auth V1
const HathoraError = preload("res://addons/hathora_api/core/error.gd").HathoraError
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson

##region     -- login_anonymous
class LoginAnonymousResponse:
	var auth_token: String
	
	var error: HathoraError
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in anonymous auth")
		self.auth_token = data["token"]


static func login_anonymous_async() -> LoginAnonymousResponse:
	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
	HathoraEventBus.on_login_anonymous.connect(
		func(response: LoginAnonymousResponse) -> void:
			result.auth_token = response.auth_token
			result.error = response.error
			result.error_message = response.error_message
	, CONNECT_ONE_SHOT)
	
	login_anonymous_sync()
	await HathoraEventBus.on_login_anonymous
	return result


static func login_anonymous_sync() -> void:
	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/anonymous")
	var api_response: ResponseJson = Http.post_sync(
		url, ["Content-Type: application/json"], {}
	)
	api_response.request_completed.connect(
		func() -> void:
			# Api errors
			result.error = api_response.error
			result.error_message = api_response.error_message
			if result.error != HathoraError.Ok:
				# Handle errors that could be missed by Http module
				pass
			else:
				result.deserialize(api_response.data)
			
			HathoraEventBus.on_login_anonymous.emit(result)
	, CONNECT_ONE_SHOT)
##endregion  -- login_anonymous


##region     -- login_nickname
class LoginNicknameResponse:
	var auth_token: String
	
	var error: HathoraError
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in nickname auth")
		self.auth_token = data["token"]


static func login_nickname_async(nickname: String) -> LoginNicknameResponse:
	var result: LoginNicknameResponse = LoginNicknameResponse.new()
	HathoraEventBus.on_login_anonymous.connect(
		func(response: LoginNicknameResponse) -> void:
			result.auth_token = response.auth_token
			result.error = response.error
			result.error_message = response.error_message
	, CONNECT_ONE_SHOT)
	
	login_nickname_sync(nickname)
	await HathoraEventBus.on_login_nickname
	return result


static func login_nickname_sync(nickname: String) -> void:
	var result: LoginNicknameResponse = LoginNicknameResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/nickname")
	var api_response: ResponseJson = Http.post_sync(
		url, ["Content-Type: application/json"], {
			"nickname": nickname
		}
	)
	api_response.request_completed.connect(
		func() -> void:
			# Api errors
			result.error = api_response.error
			result.error_message = api_response.error_message
			if result.error != HathoraError.Ok:
				# Handle errors that could be missed by Http module
				pass
			else:
				result.deserialize(api_response.data)
			
			HathoraEventBus.on_login_nickname.emit(result)
	, CONNECT_ONE_SHOT)
##endregion  -- login_nickname

##region     -- login_google
class LoginGoogleResponse:
	var auth_token: String
	
	var error: HathoraError
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in google auth")
		self.auth_token = data["token"]


static func login_google_async(id_token: String) -> LoginGoogleResponse:
	var result: LoginGoogleResponse = LoginGoogleResponse.new()
	HathoraEventBus.on_login_google.connect(
		func(response: LoginGoogleResponse) -> void:
			result.auth_token = response.auth_token
			result.error = response.error
			result.error_message = response.error_message
	, CONNECT_ONE_SHOT)
	
	login_google_sync(id_token)
	await HathoraEventBus.on_login_google
	return result


static func login_google_sync(id_token: String) -> void:
	var result: LoginGoogleResponse = LoginGoogleResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/google")
	var api_response: ResponseJson = Http.post_sync(
		url, ["Content-Type: application/json"], {
			"idToken": id_token
		}
	)
	api_response.request_completed.connect(
		func() -> void:
			# Api errors
			result.error = api_response.error
			result.error_message = api_response.error_message
			if result.error != HathoraError.Ok:
				# Handle errors that could be missed by Http module
				if api_response.status_code == 401:
					result.error = HathoraError.Unauthorized
					result.error_message = "TODO: SPECIFY ERROR MESSAGE"
			else:
				result.deserialize(api_response.data)
			
			HathoraEventBus.on_login_google.emit(result)
	, CONNECT_ONE_SHOT)
##endregion  -- login_google
