# LobbyV3
const LobbyV3 = preload("res://addons/hathora_api/api/common_types.gd").LobbyV3
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- list_active_public_lobbies
class ListActivePublicLobbiesResponse:
	var error
	var error_message: String
	
	var result: Array[LobbyV3]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(LobbyV3.deserialize(part))


static func list_active_public_lobbies_async(region: String = '') -> ListActivePublicLobbiesResponse:
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
	
	HathoraEventBus.on_list_active_public_lobbies.emit(result)
	return result


static func list_active_public_lobbies(region: String = '') -> Signal:
	list_active_public_lobbies_async(region)
	return HathoraEventBus.on_list_active_public_lobbies
#endregion    -- list_active_public_lobbies
