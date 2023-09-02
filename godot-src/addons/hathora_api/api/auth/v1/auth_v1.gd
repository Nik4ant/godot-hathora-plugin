# Auth V1
const HathoraError = preload("res://addons/hathora_api/core/error.gd").HathoraError
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson

##region     -- login_anonymous
class LoginAnonymousResponse:
	var auth_token: String = ''
	
	var status: HathoraError
	var error_message: String


static func login_anonymous() -> LoginAnonymousResponse:
	assert(HathoraClient.APP_ID != '', "ASSERT! HathoraCLient MUST have a valid APP_ID. See init() function")
	var login_response: LoginAnonymousResponse = LoginAnonymousResponse.new()
	# Api call
	var url: String = str("https://api.hathora.dev/auth/v1/", HathoraClient.APP_ID, "/login/anonymous")
	var api_response: ResponseJson = await Http.POST(
		url, ["Content-Type: application/json"], {}
	)
	# Handle response
	match api_response.status_code:
		200:
			assert(api_response.data.has("token"), "ASSERT! Missing parameter \"token\" during json parsing in anonymous auth")
			login_response.auth_token = api_response.data["token"]
		404:
			login_response.status = HathoraError.ApiDontExists
			login_response.error_message = str(
				"Can't auth user anonymously because api endpoint for url `", url, "` doesn't exist"
			)
		_:
			login_response.status = HathoraError.Unknown
			login_response.error_message = str(
				"Unknown error occured during anonymous auth: `",
				api_response.error_message, "`; http status code: ",
				api_response.status_code, "; data: ", api_response.data
			)
	
	return login_response
##endregion  -- login_anonymous
