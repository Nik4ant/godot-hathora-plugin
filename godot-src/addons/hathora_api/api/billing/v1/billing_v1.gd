# Billing v1
const Invoice = preload("res://addons/hathora_api/api/common_types.gd").Invoice
const LinkPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").LinkPaymentMethod
const AchPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").AchPaymentMethod
const CardPaymentMethod = preload("res://addons/hathora_api/api/common_types.gd").CardPaymentMethod
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_balance
class GetBalanceResponse:
	var result: float

	var error: Variant
	var error_message: String

	func deserialize(data: float) -> void:
		self.result = data


static func get_balance_async() -> GetBalanceResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetBalanceResponse = GetBalanceResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/balance"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_balance_v1.emit(result)
	return result


static func get_balance() -> Signal:
	get_balance_async()
	return HathoraEventBus.on_get_balance_v1
#endregion


#region get_payment_method
## Make all properties in T optional
class GetPaymentMethodResponse:
	## (optional)
	var card: CardPaymentMethod = null
	## (optional)
	var ach: AchPaymentMethod = null
	## (optional)
	var link: LinkPaymentMethod = null

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		if data.has("card"):
			self.card = CardPaymentMethod.deserialize(data["card"])
		
		if data.has("ach"):
			self.ach = AchPaymentMethod.deserialize(data["ach"])
		
		if data.has("link"):
			self.link = LinkPaymentMethod.deserialize(data["link"])


static func get_payment_method_async() -> GetPaymentMethodResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetPaymentMethodResponse = GetPaymentMethodResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/paymentmethod"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404, 500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_payment_method_v1.emit(result)
	return result


static func get_payment_method() -> Signal:
	get_payment_method_async()
	return HathoraEventBus.on_get_payment_method_v1
#endregion


#region init_stripe_customer_portal_url
class InitStripeCustomerPortalUrlResponse:
	var result: String

	var error: Variant
	var error_message: String

	func deserialize(data: String) -> void:
		self.result = data


static func init_stripe_customer_portal_url_async(return_url: String) -> InitStripeCustomerPortalUrlResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: InitStripeCustomerPortalUrlResponse = InitStripeCustomerPortalUrlResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/customerportalurl"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"returnUrl": return_url,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_init_stripe_customer_portal_url_v1.emit(result)
	return result


static func init_stripe_customer_portal_url(return_url: String) -> Signal:
	init_stripe_customer_portal_url_async(return_url)
	return HathoraEventBus.on_init_stripe_customer_portal_url_v1
#endregion


#region get_invoices
class GetInvoicesResponse:
	var result: Array[Invoice]

	var error: Variant
	var error_message: String

	func deserialize(data: Array[Dictionary]) -> void:
		for item: Dictionary in data:
			self.result.push_back(Invoice.deserialize(item))


static func get_invoices_async() -> GetInvoicesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetInvoicesResponse = GetInvoicesResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/invoices"

	# Api call
	var api_response: ResponseJson = await Hathora.Http.get_async(
		url,
		[Hathora.DEV_AUTH_HEADER]
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_get_invoices_v1.emit(result)
	return result


static func get_invoices() -> Signal:
	get_invoices_async()
	return HathoraEventBus.on_get_invoices_v1
#endregion


