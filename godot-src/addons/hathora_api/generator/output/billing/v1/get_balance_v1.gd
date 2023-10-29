# BillingV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_balance
class GetBalanceResponse:
	var error
	var error_message: String
	
	var result: float
	
	func deserialize(data: float) -> void:
		self.result = data


func get_balance_async() -> GetBalanceResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBalanceResponse = GetBalanceResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/balance"
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
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
	
	HathoraEventBus.on_get_balance.emit(result)
	return result


func get_balance() -> Signal:
	get_balance_async()
	return HathoraEventBus.on_get_balance
##endregion    -- get_balance
