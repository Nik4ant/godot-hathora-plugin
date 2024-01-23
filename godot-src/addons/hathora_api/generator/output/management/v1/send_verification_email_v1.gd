# ManagementV1
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region       -- send_verification_email
class SendVerificationEmailResponse:
	var error
	var error_message: String
	
	var status: String
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("status"), "Missing parameter \"status\"")
		self.status = data["status"]


static func send_verification_email_async(user_id: String) -> SendVerificationEmailResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	
	var result: SendVerificationEmailResponse = SendVerificationEmailResponse.new()
	var url: String = "https://api.hathora.dev/management/v1/sendverificationemail"
	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json"],
		{
			"userId": user_id
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: HUMAN! I need your help - write custom error messages
		# List of error codes: [500]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_send_verification_email.emit(result)
	return result


static func send_verification_email(user_id: String) -> Signal:
	send_verification_email_async(user_id)
	return HathoraEventBus.on_send_verification_email
#endregion    -- send_verification_email
