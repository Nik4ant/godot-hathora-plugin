# DeploymentV1
const Deployment = preload("res://addons/hathora_api/api/common_types.gd").Deployment
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


##region       -- get_deployments
class GetDeploymentsResponse:
	var error
	var error_message: String
	
	var result: Array[Deployment]
	
	func deserialize(data: Array[Dictionary]) -> void:
		for part in data:
			self.result.push_back(Deployment.deserialize(part))


func get_deployments_async() -> GetDeploymentsResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetDeploymentsResponse = GetDeploymentsResponse.new()
	var url: String = "https://api.hathora.dev/deployments/v1/{appId}/list".format(
		{
			"appId": Hathora.APP_ID
		}
	)
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
	
	HathoraEventBus.on_get_deployments.emit(result)
	return result


func get_deployments() -> Signal:
	get_deployments_async()
	return HathoraEventBus.on_get_deployments
##endregion    -- get_deployments
