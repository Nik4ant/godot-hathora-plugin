# LobbyV3
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_lobby_info_by_short_code
class GetLobbyInfoByShortCodeResponse:
	var error
	var error_message: String
	
	var short_code: String
	var created_at_unix: int
	var created_by: String
	var room_config: String
	var visibility: String
	var region: String
	var room_id: String
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("shortCode"), "Missing parameter \"shortCode\"")
		self.short_code = data["shortCode"]
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("roomConfig"), "Missing parameter \"roomConfig\"")
		self.room_config = data["roomConfig"]
		
		assert(data.has("visibility"), "Missing parameter \"visibility\"")
		self.visibility = data["visibility"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		self.region = data["region"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


func get_lobby_info_by_short_code_async(short_code: String) -> GetLobbyInfoByShortCodeResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetLobbyInfoByShortCodeResponse = GetLobbyInfoByShortCodeResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/info/shortcode/{shortCode}".format(
		{
			"appId": Hathora.APP_ID,
			"shortCode": short_code
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json"]
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
	
	HathoraEventBus.on_get_lobby_info_by_short_code.emit(result)
	return result


func get_lobby_info_by_short_code(short_code: String) -> Signal:
	get_lobby_info_by_short_code_async(short_code)
	return HathoraEventBus.on_get_lobby_info_by_short_code
##endregion    -- get_lobby_info_by_short_code
