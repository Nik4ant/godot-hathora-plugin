# Note(Nik4ant): As much as I would love to use an enum here, I can't
# (Get back to this message if there is a better design idea)

# This way plugins' Ok code is the same as Godot's @GlobalScope.OK
const Ok = OK
## Error occured, but its cause is unknown
const Unknown = FAILED
#region     -- Internal errors 
## Client can't perform a HTTP request for [whatever] reason
const InternalHttpError = 2
const JsonError = 4
# ...
#endregion  -- Internal errors  
#region     -- API errors
const BadRequest = 400
## Authecation is required in order to call certain APIs.
## Eiter with user's auth_token or DEV_TOKEN
const Unauthorized = 401
## In order to access something you must pay for it first
const MustPayFirst = 402
## You're not allowed to access this
const Forbidden = 403
## Calling API endpoint that doesn't exists
const ApiDontExists = 404
## Server can't process data given to it despite data being valid
const ServerCantProcess = 422
const TooManyRequests = 429
## Something went wrong on the server side
const ServerError = 500
#endregion  -- API errors

const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson
## int (errors above): String (error message)
const DEFAULT_ERRORS: Dictionary = {
	Unknown: "An unknown error occured",
	ApiDontExists: "`{url}` doesn't exist",
	Unauthorized: "Authentication is required to use `{url}`",
	ServerCantProcess: "Data can't be processed by `{url}`"
}
## int (errors above): Array[String] (possible hint messages)
const DEFAULT_HINTS: Dictionary = {
	Unknown: [
		"Make sure you didn't do anything on your end",
		"Contact the developer (or Discord community)"
	],
	Unauthorized: [
		"Make sure you're using correct auth/dev token",
	],
	# Note: Base url is always valid since it's defined on plugin side
	ApiDontExists: [
		"Make sure app with initialized APP_ID exists"
	],
	ServerCantProcess: [
		"Make sure all your params use valid length, format, etc."
	]
}
## TODO: explain TL;DR - this is for internal use only
static func push_default_or(request: ResponseJson, custom_hints: Dictionary = {}, custom_messages: Dictionary = {}) -> String:
	var error_message: String
	if custom_messages.has(request.error):
		# Custom error message
		error_message = custom_messages[request.error]
	else:
		# If default message doesn't exist use one from the request
		if DEFAULT_ERRORS.has(request.error):
			error_message = DEFAULT_ERRORS[request.error].format({"url": request.url})
		else:
			error_message = request.error_message
	
	assert(error_message != '', "ASSERT! Unknown error on the plugin side, please report")
	push_error(error_message)
	# Most of the time API response contains an error info
	# (See Http module to see how it's parsed)
	if request.data.has("__message__"):
		push_error("Message from API: `" + request.data["__message__"], '`')
	
	var hint_message: String = ''
	var hints: Array = custom_hints.get(request.error, [])
	if len(hints) != 0:
		hint_message = str(
			"\nSpecific hints to recent error:\n- ", "\n-".join(hints)
		)
	var default_hints: Array = DEFAULT_HINTS.get(request.error, [])
	if len(default_hints) != 0:
		hint_message += str(
			"\nDefault hints to recent error:\n- ", "\n-".join(default_hints)
		)
	
	if hint_message != '':
		push_warning(hint_message)
		print(hint_message)
	
	return error_message
