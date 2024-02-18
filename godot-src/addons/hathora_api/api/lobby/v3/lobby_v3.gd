# LobbyV3
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson
const LobbyV3 = preload("res://addons/hathora_api/api/common_types.gd").LobbyV3


#region       -- create_lobby
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


static func create_lobby_async(auth_token: String, visibility: String, region: String, room_id: String = '', short_code: String = '', room_config: String = '') -> CreateLobbyResponse:
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
			"shortCode": short_code,
			"roomId": room_id
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
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [400, 401, 404, 422, 429, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	Hathora.EventBus.on_create_lobby.emit(result)
	return result


static func create_lobby(auth_token: String, visibility: String, region: String, room_config: String = '', short_code: String = '', room_id: String = '') -> Signal:
	create_lobby_async(auth_token, visibility, region, room_config, short_code, room_id)
	return Hathora.EventBus.on_create_lobby
#endregion    -- create_lobby


#region       -- get_lobby_info_by_room_id
class GetLobbyInfoByRoomIdResponse:
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


func get_lobby_info_by_room_id_async(room_id: String) -> GetLobbyInfoByRoomIdResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetLobbyInfoByRoomIdResponse = GetLobbyInfoByRoomIdResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/info/roomid/{roomId}".format(
		{
			"appId": Hathora.APP_ID,
			"roomId": room_id
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
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	Hathora.EventBus.on_get_lobby_info_by_room_id.emit(result)
	return result


func get_lobby_info_by_room_id(room_id: String) -> Signal:
	get_lobby_info_by_room_id_async(room_id)
	return Hathora.EventBus.on_get_lobby_info_by_room_id
#endregion    -- get_lobby_info_by_room_id


#region       -- get_lobby_info_by_short_code
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
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	Hathora.EventBus.on_get_lobby_info_by_short_code.emit(result)
	return result


func get_lobby_info_by_short_code(short_code: String) -> Signal:
	get_lobby_info_by_short_code_async(short_code)
	return Hathora.EventBus.on_get_lobby_info_by_short_code
#endregion    -- get_lobby_info_by_short_code


#region       -- list_active_public_lobbies
class ListActivePublicLobbiesResponse:
	var error
	var error_message: String
	
	var result: Array[LobbyV3]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(LobbyV3.deserialize(part))


func list_active_public_lobbies_async(region: String = '') -> ListActivePublicLobbiesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	
	var result: ListActivePublicLobbiesResponse = ListActivePublicLobbiesResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/list/public".format(
		{
			"appId": Hathora.APP_ID
		}
	)
	url += Hathora.Http.build_query_params(
		{
			"region": region
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
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	Hathora.EventBus.on_list_active_public_lobbies.emit(result)
	return result


func list_active_public_lobbies(region: String = '') -> Signal:
	list_active_public_lobbies_async(region)
	return Hathora.EventBus.on_list_active_public_lobbies
#endregion    -- list_active_public_lobbies
