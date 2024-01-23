# BillingV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- init_stripe_customer_portal_url
class InitStripeCustomerPortalUrlResponse:
	var error
	var error_message: String
	
	var result: String
	
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
			"returnUrl": return_url
		}
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
	
	HathoraEventBus.on_init_stripe_customer_portal_url.emit(result)
	return result


static func init_stripe_customer_portal_url(return_url: String) -> Signal:
	init_stripe_customer_portal_url_async(return_url)
	return HathoraEventBus.on_init_stripe_customer_portal_url
#endregion    -- init_stripe_customer_portal_url
