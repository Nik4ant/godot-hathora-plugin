# Lobby v3
const LobbyV3 = preload("res://addons/hathora_api/api/common_types.gd").LobbyV3
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region create_lobby
## A lobby object allows you to store and manage metadata for your rooms.
class CreateLobbyResponse:
	## User-defined identifier for a lobby.
	var short_code: String
	## When the lobby was created.
	var created_at_unix: int
	## UserId or email address for the user that created the lobby.
	var created_by: String
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Types of lobbies a player can create.
	## `private`: the player who created the room must share the roomId with their friends
	## `public`: visible in the public lobby list, anyone can join
	## `local`: for testing with a server running locally
	var visibility: String
	var region: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

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


static func create_lobby_async(auth_token: String, visibility: String, region: String, room_config: String = '', short_code: String = '', room_id: String = '') -> CreateLobbyResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.VISIBILITIES.has(visibility), "ASSERT! Visibility `" + visibility + "` doesn't exists")
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	
	var result: CreateLobbyResponse = CreateLobbyResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/create".format({
			"appId": Hathora.APP_ID,
		}
	)

	url += Hathora.Http.build_query_params({
			"shortCode": short_code,
			"roomId": room_id,
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", "Authorization: " + auth_token],
		{
			"visibility": visibility,
			"roomConfig": room_config,
			"region": region,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [400, 401, 402, 404, 422, 429, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_lobby_v3.emit(result)
	return result


static func create_lobby(auth_token: String, visibility: String, region: String, room_config: String = '', short_code: String = '', room_id: String = '') -> Signal:
	create_lobby_async(auth_token, visibility, region, room_config, short_code, room_id)
	return HathoraEventBus.on_create_lobby_v3
#endregion


#region list_active_public_lobbies
class ListActivePublicLobbiesResponse:
	var result: Array[LobbyV3]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(LobbyV3.deserialize(item))


static func list_active_public_lobbies_async(region: String = '') -> ListActivePublicLobbiesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	
	var result: ListActivePublicLobbiesResponse = ListActivePublicLobbiesResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/list/public".format({
			"appId": Hathora.APP_ID,
		}
	)

	url += Hathora.Http.build_query_params({
			"region": region,
		}
	)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_list_active_public_lobbies_v3.emit(result)
	return result


static func list_active_public_lobbies(region: String = '') -> Signal:
	list_active_public_lobbies_async(region)
	return HathoraEventBus.on_list_active_public_lobbies_v3
#endregion


#region get_lobby_info_by_room_id
## A lobby object allows you to store and manage metadata for your rooms.
class GetLobbyInfoByRoomIdResponse:
	## User-defined identifier for a lobby.
	var short_code: String
	## When the lobby was created.
	var created_at_unix: int
	## UserId or email address for the user that created the lobby.
	var created_by: String
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Types of lobbies a player can create.
	## `private`: the player who created the room must share the roomId with their friends
	## `public`: visible in the public lobby list, anyone can join
	## `local`: for testing with a server running locally
	var visibility: String
	var region: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

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


static func get_lobby_info_by_room_id_async(room_id: String) -> GetLobbyInfoByRoomIdResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetLobbyInfoByRoomIdResponse = GetLobbyInfoByRoomIdResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/info/roomid/{roomId}".format({
			"appId": Hathora.APP_ID,
			"roomId": room_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_lobby_info_by_room_id_v3.emit(result)
	return result


static func get_lobby_info_by_room_id(room_id: String) -> Signal:
	get_lobby_info_by_room_id_async(room_id)
	return HathoraEventBus.on_get_lobby_info_by_room_id_v3
#endregion


#region get_lobby_info_by_short_code
## A lobby object allows you to store and manage metadata for your rooms.
class GetLobbyInfoByShortCodeResponse:
	## User-defined identifier for a lobby.
	var short_code: String
	## When the lobby was created.
	var created_at_unix: int
	## UserId or email address for the user that created the lobby.
	var created_by: String
	## Optional configuration parameters for the room. Can be any string including stringified JSON. It is accessible from the room via [`GetRoomInfo()`](https://hathora.dev/api#tag/RoomV2/operation/GetRoomInfo).
	var room_config: String
	## Types of lobbies a player can create.
	## `private`: the player who created the room must share the roomId with their friends
	## `public`: visible in the public lobby list, anyone can join
	## `local`: for testing with a server running locally
	var visibility: String
	var region: String
	## Unique identifier to a game session or match. Use the default system generated ID or overwrite it with your own.
	## Note: error will be returned if `roomId` is not globally unique.
	var room_id: String
	## System generated unique identifier for an application.
	var app_id: String

	var error: Variant
	var error_message: String

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


static func get_lobby_info_by_short_code_async(short_code: String) -> GetLobbyInfoByShortCodeResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetLobbyInfoByShortCodeResponse = GetLobbyInfoByShortCodeResponse.new()
	var url: String = "https://api.hathora.dev/lobby/v3/{appId}/info/shortcode/{shortCode}".format({
			"appId": Hathora.APP_ID,
			"shortCode": short_code,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_lobby_info_by_short_code_v3.emit(result)
	return result


static func get_lobby_info_by_short_code(short_code: String) -> Signal:
	get_lobby_info_by_short_code_async(short_code)
	return HathoraEventBus.on_get_lobby_info_by_short_code_v3
#endregion


