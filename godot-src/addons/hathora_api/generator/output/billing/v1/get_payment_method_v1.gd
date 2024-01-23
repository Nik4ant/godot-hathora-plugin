# BillingV1
const LinkPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").LinkPaymentMethod
const AchPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").AchPaymentMethod
const CardPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").CardPaymentMethod
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- get_payment_method
class GetPaymentMethodResponse:
	var error
	var error_message: String
	
	var card: CardPaymentMethod
	var ach: AchPaymentMethod
	var link: LinkPaymentMethod
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("card"), "Missing parameter \"card\"")
		self.card = CardPaymentMethod.deserialize(data["card"])
		
		assert(data.has("ach"), "Missing parameter \"ach\"")
		self.ach = AchPaymentMethod.deserialize(data["ach"])
		
		assert(data.has("link"), "Missing parameter \"link\"")
		self.link = LinkPaymentMethod.deserialize(data["link"])


static func get_payment_method_async() -> GetPaymentMethodResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetPaymentMethodResponse = GetPaymentMethodResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/paymentmethod"
	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_payment_method.emit(result)
	return result


static func get_payment_method() -> Signal:
	get_payment_method_async()
	return HathoraEventBus.on_get_payment_method
#endregion    -- get_payment_method
