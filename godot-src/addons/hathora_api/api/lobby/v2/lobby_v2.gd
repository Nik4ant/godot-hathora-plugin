# Lobby V2
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson
const Lobby = preload("res://addons/hathora_api/api/common_types.gd").Lobby

##region       -- create_lobby
class CreateLobbyResponse:
	var lobby: Lobby
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		self.lobby = Lobby.deserialize(data)


static func create_lobby_async(auth_token: String, visibility: String, region: String, initial_config: Dictionary = {}, room_id: String = '') -> CreateLobbyResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	# Validation
	assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
	assert(Hathora.VISIBILITIES.has(visibility), "ASSERT! Visibility `" + visibility + "` doesn't exists")
	
	var result: CreateLobbyResponse = CreateLobbyResponse.new()
	var url: String = str("https://api.hathora.dev/lobby/v2/", Hathora.APP_ID, "/create")
	if room_id != '':
		url += "?roomId=" + room_id
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
	# Api error
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		var cant_process_hint: Array = []
		if room_id != '':
			cant_process_hint.push_back("Make sure your custom room_id `" + room_id + '` is valid')
		
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ServerCantProcess: cant_process_hint,
				Hathora.Error.TooManyRequests: ["Make sure you're not calling this method too often"]
			},
			{
				Hathora.Error.TooManyRequests: "Client attempts to create too many lobbies"
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_lobby.emit(result)
	return result


static func create_lobby(auth_token: String, visibility: String, region: String, initial_config: Dictionary = {}, room_id: String = '') -> Signal:
	create_lobby_async(auth_token, visibility, region, initial_config, room_id)
	return HathoraEventBus.on_create_lobby
#endregion     -- create_lobby
 

##region       -- list_active_public_lobbies
class ListActivePublicLobbiesResponse:
	var lobbies: Array[Lobby] = []
	
	var error
	var error_message: String
	
	func deserialize(data) -> void:
		for lobby in data:
			self.lobbies.push_back(Lobby.deserialize(lobby))


static func list_active_public_lobbies_async(region: String = '') -> ListActivePublicLobbiesResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	
	var result: ListActivePublicLobbiesResponse = ListActivePublicLobbiesResponse.new()
	var url: String = str("https://api.hathora.dev/lobby/v2/", Hathora.APP_ID, "/list/public")
	if region != '':
		assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn't exists")
		url += "?region=" + region
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json"]
	)
	# Api errors
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(api_response)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_list_active_public_lobbies.emit(result)
	return result


static func list_active_public_lobbies(region: String = '') -> Signal:
	list_active_public_lobbies_async(region)
	return HathoraEventBus.on_list_active_public_lobbies
##endregion    -- list_active_public_lobbies


##region       -- get_lobby_info
class GetLobbyInfoResponse:
	var lobby: Lobby
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		self.lobby = Lobby.deserialize(data)


static func get_lobby_info_async(room_id: String) -> GetLobbyInfoResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	
	var result: GetLobbyInfoResponse = GetLobbyInfoResponse.new()
	var url: String = str("https://api.hathora.dev/lobby/v2/", Hathora.APP_ID, "/info/", room_id)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url, ["Content-Type: application/json"]
	)
	# Api error
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with id `" + room_id, "` exists"]
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_lobby_info.emit(result)
	return result


static func get_lobby_info(room_id: String) -> Signal:
	get_lobby_info_async(room_id)
	return HathoraEventBus.on_get_lobby_info
##endregion    -- get_lobby_info


##region       -- set_lobby_state
class SetLobbyStateResponse:
	var lobby: Lobby
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		self.lobby = Lobby.deserialize(data)


static func set_lobby_state_async(room_id: String, state: Dictionary) -> SetLobbyStateResponse:
	assert(Hathora.APP_ID != '', "ASSERT! Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), '')
	
	var result: SetLobbyStateResponse = SetLobbyStateResponse.new()
	var url: String = str("https://api.hathora.dev/lobby/v2/", Hathora.APP_ID, "/setState/", room_id)
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url, ["Content-Type: application/json", Hathora.DEV_AUTH_HEADER], {"state": state}
	)
	# Api error
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {
				Hathora.Error.ApiDontExists: ["Make sure room with id `" + room_id, "` exists"],
				Hathora.Error.ServerCantProcess: ["Make sure your state is valid an smaller than 1MB"]
			}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_set_lobby_state.emit(result)
	return result


static func set_lobby_state(room_id: String, state: Dictionary) -> Signal:
	set_lobby_state_async(room_id, state)
	return HathoraEventBus.on_set_lobby_state
##endregion    -- set_lobby_state
