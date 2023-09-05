# Auth V1
const HathoraError = preload("res://addons/hathora_api/core/error.gd").HathoraError
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson

##region     -- login_anonymous
class LoginAnonymousResponse:
	var auth_token: String
	
	var error: HathoraError
	var error_message: String


#static func login_anonymous() -> LoginAnonymousResponse:
#	assert(HathoraClient.APP_ID != '', "ASSERT! HathoraCLient MUST have a valid APP_ID. See init() function")
#	var login_response: LoginAnonymousResponse = LoginAnonymousResponse.new()
#	# Api call
#	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/anonymous")
#	var api_response: ResponseJson = await Http.POST(
#		url, ["Content-Type: application/json"], {}
#	)
#	# Handle response
#	match api_response.status_code:
#		200:
#			assert(api_response.data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in anonymous auth")
#			login_response.auth_token = api_response.data["token"]
#		404:
#			login_response.error = HathoraError.ApiDontExists
#			login_response.error_message = str(
#				"Can't auth user anonymously because api endpoint `", url, "` doesn't exist"
#			)
#		_:
#			login_response.error = HathoraError.Unknown
#			login_response.error_message = str(
#				"Unknown error occured during anonymous auth: `",
#				api_response.error_message, "`; http status code: ",
#				api_response.status_code, "; data: ", api_response.data
#			)
#
#	return login_response


static func login_anonymous_async() -> LoginAnonymousResponse:
	assert(HathoraClient.APP_ID != '', "ASSERT! HathoraCLient MUST have a valid APP_ID. See init() function")
	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/anonymous")
	var api_response: ResponseJson = await Http.POST(
		url, ["Content-Type: application/json"], {}
	)
	# Api errors
	result.error = api_response.error
	result.error_message = api_response.error_message
	if result.error == HathoraError.Unknown:
		# Handle errors that could be missed by Http module
		pass
	else:
		assert(api_response.data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in anonymous auth")
		result.auth_token = api_response.data["token"]
	
	return result


# TODO: add event bus thingy?
#signal on_login_anonymous_sync(response: LoginAnonymousResponse)
#static func login_anonymous_sync() -> void:
#	var result: LoginAnonymousResponse = LoginAnonymousResponse.new()
#	on_login_anonymous_sync.emit(result)

##endregion  -- login_anonymous
