# BillingV1
const Invoice = preload("res://addons/hathora_api/api/common_types.gd").Invoice
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_invoices
class GetInvoicesResponse:
	var error
	var error_message: String
	
	var result: Array[Invoice]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(Invoice.deserialize(part))


func get_invoices_async() -> GetInvoicesResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetInvoicesResponse = GetInvoicesResponse.new()
	var url: String = "https://api.hathora.dev/billing/v1/invoices"
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
	
	HathoraEventBus.on_get_invoices.emit(result)
	return result


func get_invoices() -> Signal:
	get_invoices_async()
	return HathoraEventBus.on_get_invoices
##endregion    -- get_invoices
