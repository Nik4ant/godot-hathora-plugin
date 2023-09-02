enum HathoraError {
	# This way HathoraError.Ok is the same as Godot's @GlobalScope.OK
	Ok = OK,
	## Error occured, but its cause is unknown
	Unknown,
	
	#region     -- API errors
	BadRequest,  # 400
	## Authecation is required in order to call certain APIs.
	## Eiter with user's auth_token or DEV_TOKEN
	Unauthorized,  # 401
	## Calling API endpoint that doesn't exists
	ApiDontExists,  # 404
	## Server can't process data given to it despite data being valid
	ServerCantProcess,  # 422
	## 
	TooManyRequests,  # 429
	ServerError,  # 500
	# ...
	#endregion  -- API errors
	
	#region     -- Internal errors 
	HttpError,
	JsonError,
	# ...
	#endregion  -- Internal errors  
}
