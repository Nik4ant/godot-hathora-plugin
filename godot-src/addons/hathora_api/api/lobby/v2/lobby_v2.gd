# Lobby V2
const HathoraError = preload("res://addons/hathora_api/core/error.gd").HathoraError
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson

class CreateLobbyResponse:
	var initial_config: Dictionary
	var created_at_unix: int
	var created_by: String
	var visibility: String
	var region: String
	var room_id: String
	var app_id: String
	
	var status: HathoraError
	var error_message: String = ''


static func create(auth_token: String, visibility: String, region: String, initial_config: Dictionary = {}, room_id: String = '') -> CreateLobbyResponse:
	assert(HathoraClient.APP_ID != '', "ASSERT! HathoraCLient MUST have a valid APP_ID. See init() function")
	# Params validation
	assert(HathoraConstants.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	assert(HathoraConstants.VISIBILITIES.has(visibility), "ASSERT! Visibility `" + visibility + "` doesn't exists")
	
	var create_response: CreateLobbyResponse = CreateLobbyResponse.new()
	var url: String = str("https://api.hathora.dev/lobby/v2/", HathoraClient.APP_ID, "/create")
	if room_id != '':
		url += "?roomId=" + room_id
	# Api call
	var api_response: ResponseJson = await Http.POST(
		url, 
		["Content-Type: application/json", "Authorization: " + auth_token], 
		{
			"visibility": visibility,
			"initialConfig": initial_config,
			"region": region
		}
	)
	# On success
	# TODO: replace that with a for loop OR generate automatically
	if api_response.status_code == 201:
		create_response.status = HathoraError.Ok
		
		assert(api_response.data.has("initialConfig"), "ASSERT! Missing parameter \"initialConfig\" during json parsing in lobby creation")
		create_response.initial_config = api_response.data["initialConfig"]
		
		assert(api_response.data.has("createdAt"), "ASSERT! Missing parameter \"createdAt\" during json parsing in lobby creation")
		create_response.created_at_unix = Time.get_unix_time_from_datetime_string(api_response.data["createdAt"])
		
		assert(api_response.data.has("createdBy"), "ASSERT! Missing parameter \"createdBy\" during json parsing in lobby creation")
		create_response.created_by = api_response.data["createdBy"]
		
		assert(api_response.data.has("visibility"), "ASSERT! Missing parameter \"visibility\" during json parsing in lobby creation")
		create_response.visibility = api_response.data["visibility"]
		
		assert(api_response.data.has("region"), "ASSERT! Missing parameter \"region\" during json parsing in lobby creation")
		create_response.region = api_response.data["region"]
		
		assert(api_response.data.has("roomId"), "ASSERT! Missing parameter \"roomId\" during json parsing in lobby creation")
		create_response.room_id = api_response.data["roomId"]
		
		assert(api_response.data.has("appId"), "ASSERT! Missing parameter \"appId\" during json parsing in lobby creation")
		create_response.app_id = api_response.data["appId"]
		return create_response
	
	# Handle errors
	match api_response.status_code:
		400:
			create_response.status = HathoraError.BadRequest
			create_response.error_message = str(
				"Something is wrong with your request to `", url,
				"` Message: `", api_response.error_message,
				"` Response data: ", api_response.data
			)
		401:
			create_response.status = HathoraError.Unauthorized
			create_response.error_message = str(
				"Can't create lobby because auth token is invalid"
			)
		404:
			create_response.status = HathoraError.ApiDontExists
			create_response.error_message = str(
				"Can't create lobby because api endpoint for url `", url, "` doesn't exist"
			)
		422:
			create_response.status = HathoraError.ServerCantProcess
			create_response.error_message = str(
				"Server can't process data given to it. Message: `", api_response.error_message,
				"`. Response data: ", api_response.data
			)
		429:
			create_response.status = HathoraError.TooManyRequests
			create_response.error_message = str(
				"User with token `", auth_token, "` exited lobby creation limit. Try again later"
			)
		500:
			create_response.status = HathoraError.ServerError
			create_response.error_message = str(
				"Hathora servers don't respond: `", api_response.error_message, '`'
			)
		_:
			create_response.status = HathoraError.Unknown
			create_response.error_message = str(
				"Unknown error occured during lobby creation: `",
				api_response.error_message, "`; http status code: ",
				api_response.status_code, "; data: ", api_response.data
			)
	
	push_error(create_response.error_message)
	return create_response
