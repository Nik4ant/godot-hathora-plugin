# LobbyV2
const Lobby = preload("res://addons/hathora_api/api/common_types.gd").Lobby
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- list_active_public_lobbies_deprecated_v_2
class ListActivePublicLobbiesDeprecatedV2Response:
	var error
	var error_message: String
	
	var result: Array[Lobby]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(Lobby.deserialize(part))


func list_active_public_lobbies_deprecated_v_2_async(region: String = '') -> ListActivePublicLobbiesDeprecatedV2Response:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.REGIONS.has(region), "Region `" + region + "` doesn't exists")
	
	var result: ListActivePublicLobbiesDeprecatedV2Response = ListActivePublicLobbiesDeprecatedV2Response.new()
	var url: String = "https://api.hathora.dev/lobby/v2/{appId}/list/public".format(
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
		# HUMAN! I need your help - write error messages pls
		# List of error codes: []
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_list_active_public_lobbies_deprecated_v_2.emit(result)
	return result


func list_active_public_lobbies_deprecated_v_2(region: String = '') -> Signal:
	list_active_public_lobbies_deprecated_v_2_async(region)
	return HathoraEventBus.on_list_active_public_lobbies_deprecated_v_2
##endregion    -- list_active_public_lobbies_deprecated_v_2
