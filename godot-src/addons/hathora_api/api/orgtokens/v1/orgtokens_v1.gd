# Orgtokens v1
const OrgToken = preload("res://addons/hathora_api/api/common_types.gd").OrgToken
const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson


#region get_org_tokens
class GetOrgTokensResponse:
	var tokens: Array[OrgToken]

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("tokens"), "Missing parameter \"tokens\"")
		for item: Dictionary in data["tokens"]:
			self.tokens.push_back(OrgToken.deserialize(item))


static func get_org_tokens_async(org_id: String) -> GetOrgTokensResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: GetOrgTokensResponse = GetOrgTokensResponse.new()
	var url: String = "https://api.hathora.dev/tokens/v1/orgs/{orgId}".format({
			"orgId": org_id,
		}
	)

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
	
	HathoraEventBus.on_get_org_tokens_v1.emit(result)
	return result


static func get_org_tokens(org_id: String) -> Signal:
	get_org_tokens_async(org_id)
	return HathoraEventBus.on_get_org_tokens_v1
#endregion


#region create_org_token
class CreateOrgTokenResponse:
	var plain_text_token: String
	var org_token: OrgToken

	var error: Variant
	var error_message: String

	func deserialize(data: Dictionary) -> void:
		assert(data.has("plainTextToken"), "Missing parameter \"plainTextToken\"")
		self.plain_text_token = data["plainTextToken"]
		
		assert(data.has("orgToken"), "Missing parameter \"orgToken\"")
		self.org_token = OrgToken.deserialize(data["orgToken"])


static func create_org_token_async(name: String, org_id: String) -> CreateOrgTokenResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: CreateOrgTokenResponse = CreateOrgTokenResponse.new()
	var url: String = "https://api.hathora.dev/tokens/v1/orgs/{orgId}/create".format({
			"orgId": org_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		["Content-Type: application/json", Hathora.DEV_AUTH_HEADER],
		{
			"name": name,
		}
	)
	# Api errors
	result.error = api_response.error
	if result.error != Hathora.Error.Ok:
		# WARNING: Human! I need your help - write custom error messages
		# List of error codes: [401, 404, 422]
		result.error_message = Hathora.Error.push_default_or(
			api_response, {}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_create_org_token_v1.emit(result)
	return result


static func create_org_token(name: String, org_id: String) -> Signal:
	create_org_token_async(name, org_id)
	return HathoraEventBus.on_create_org_token_v1
#endregion


#region revoke_org_token
class RevokeOrgTokenResponse:
	var result: bool

	var error: Variant
	var error_message: String

	func deserialize(data: bool) -> void:
		self.result = data


static func revoke_org_token_async(org_id: String, org_token_id: String) -> RevokeOrgTokenResponse:
	assert(Hathora.APP_ID != '', "Hathora MUST have a valid APP_ID. See init() function")
	assert(Hathora.assert_is_server(), "unreacheble")
	
	var result: RevokeOrgTokenResponse = RevokeOrgTokenResponse.new()
	var url: String = "https://api.hathora.dev/tokens/v1/orgs/{orgId}/tokens/{orgTokenId}/revoke".format({
			"orgId": org_id,
			"orgTokenId": org_token_id,
		}
	)

	# Api call
	var api_response: ResponseJson = await Hathora.Http.post_async(
		url,
		[Hathora.DEV_AUTH_HEADER],
		{
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
	
	HathoraEventBus.on_revoke_org_token_v1.emit(result)
	return result


static func revoke_org_token(org_id: String, org_token_id: String) -> Signal:
	revoke_org_token_async(org_id, org_token_id)
	return HathoraEventBus.on_revoke_org_token_v1
#endregion


