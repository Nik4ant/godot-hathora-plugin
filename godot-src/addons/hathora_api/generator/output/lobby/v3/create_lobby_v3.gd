# LobbyV3
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- create_lobby
class CreateLobbyResponse:
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


func create_lobby_async(auth_token: String, visibility: String, room_config: String, region: String, short_code: String = '') -> CreateLobbyResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	assert(Hathora.VISIBILITIES.has(visibility), "Visibility `" + visibility + "` doesn't exists")
	
	var result: CreateLobbyResponse = CreateLobbyResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/create".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"shortCode": short_code
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", "Authorization: " + auth_token],
		{
			"visibility": visibility,
			"roomConfig": room_config,
			"region": region
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# HUMAN! I need your help - write error messages pls
		# List of error codes: [400, 401, 404, 422, 429, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_lobby.emit(result)
	return result


func create_lobby(auth_token: String, visibility: String, room_config: String, region: String, short_code: String = '') -> Signal:
	create_lobby_async(auth_token, visibility, room_config, region, short_code)
	return HathoraEventBus.on_create_lobby
##endregion    -- create_lobby
