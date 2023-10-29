# LobbyV2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- create_lobby_deprecated
class CreateLobbyDeprecatedResponse:
	var error
	var error_message: String
	
	var short_code: String
	var state: Dictionary
	var initial_config: Dictionary
	var created_at_unix: int
	var created_by: String
	var local: bool
	var visibility: String
	var region: String
	var room_id: String
	var app_id: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("shortCode"), "Missing parameter \"shortCode\"")
		self.short_code = data["shortCode"]
		
		assert(data.has("state"), "Missing parameter \"state\"")
		self.state = data["state"]
		
		assert(data.has("initialConfig"), "Missing parameter \"initialConfig\"")
		self.initial_config = data["initialConfig"]
		
		assert(data.has("createdAt"), "Missing parameter \"createdAt\"")
		self.created_at_unix = Time.get_unix_time_from_datetime_string(data["createdAt"])
		
		assert(data.has("createdBy"), "Missing parameter \"createdBy\"")
		self.created_by = data["createdBy"]
		
		assert(data.has("local"), "Missing parameter \"local\"")
		self.local = data["local"]
		
		assert(data.has("visibility"), "Missing parameter \"visibility\"")
		self.visibility = data["visibility"]
		
		assert(data.has("region"), "Missing parameter \"region\"")
		self.region = data["region"]
		
		assert(data.has("roomId"), "Missing parameter \"roomId\"")
		self.room_id = data["roomId"]
		
		assert(data.has("appId"), "Missing parameter \"appId\"")
		self.app_id = data["appId"]


func create_lobby_deprecated_async(auth_token: String, visibility: String, initial_config: Dictionary, region: String, room_id: String = '') -> CreateLobbyDeprecatedResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	assert(Hathora.VISIBILITIES.has(visibility), "Visibility `" + visibility + "` doesn't exists")
	
	var result: CreateLobbyDeprecatedResponse = CreateLobbyDeprecatedResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v2/{appId}/create".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"roomId": room_id
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", "Authorization: " + auth_token],
		{
			"visibility": visibility,
			"initialConfig": initial_config,
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
	
	HathoraEventBus.on_create_lobby_deprecated.emit(result)
	return result


func create_lobby_deprecated(auth_token: String, visibility: String, initial_config: Dictionary, region: String, room_id: String = '') -> Signal:
	create_lobby_deprecated_async(auth_token, visibility, initial_config, region, room_id)
	return HathoraEventBus.on_create_lobby_deprecated
##endregion    -- create_lobby_deprecated
