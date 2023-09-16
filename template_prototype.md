# Code generation
Would be nice to generate most (if not all) of the code using API schema.

Here's a small example of how template for an API endpoint could look like: ```
{% response_class_name %} = {% endpoint_name %}.upper() + Response

##region   -- {% endpoint_name %}
class {% response_class_name %}:
	{% endpoint_response_fields %}
	
	var error
	var error_message: String
	
	func deserialize(data: Dictionary) -> void:
		{{ manually generated here based on {% endpoint_response_fields %} }}
		


static func {% endpoint_name %}_async({% endpoint_params %}) -> {% response_class_name %}:
	{% default_asserts %}
	{% server_asserts (if any) %}
	
	var result: {% response_class_name %} = {% response_class_name %}.new()
	
	var url: String = {% endpoint_url %}.format({"appId": Hathora.APP_ID})
	# Api call
	var api_response: ResponseJson = await Http.{% endpoint_request_type %}_async(
		url, ["Content-Type: application/json", {% dev_auth_if_required %}], 
		{% endpoint_params (if a dictionary format, if any) %}
	)
	result.error = api_response.error
	if api_response.error != Hathora.Error.Ok:
		result.error_message = Hathora.Error.push_default_or(
			api_response, {% custom_errors %}, {% custom_hints %}
		)
	else:
		result.deserialize(api_response.data)
	
	HathoraEventBus.on_{% endpoint_name %}.emit(result)
	return result


static func {% endpoint_name %}({% endpoint_params %}) -> Signal:
	{% endpoint_name %}_async({% endpoint_params %})
	return HathoraEventBus.on_{% endpoint_name %}
#endregion -- {% endpoint_name %}
```