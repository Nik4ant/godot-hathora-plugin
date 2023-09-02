extends Node

const V1: Script = preload("res://addons/hathora_api/api/v1/v1.gd")
const V2: Script = preload("res://addons/hathora_api/api/v2/v2.gd")

@onready var http_request: HTTPRequest = $http

#region     -- Configuration
@export var APP_ID: String
## Is current instance running on the server OR on the client
@export var is_client: bool = false
## Dev token for Hathora API
## (Exists ONLY IF is_client is false, meaning it's server-side)
@export var DEV_TOKEN: String = ''
#endregion  -- Configuration


## Initiailizes 
func init(app_id: String, is_client: bool = true, dev_token: String = '') -> void:
	if self.APP_ID == app_id:
		push_warning("WARNING! Initializing HathoraClient more than once won't do anything")
		return
	
	Http.init(http_request)
	self.APP_ID = app_id
	
	# Setting dev token only on the server-side
	if not is_client:
		assert(dev_token != '', "ASSERT! Server-side api MUST have a valid dev token")
		self.DEV_TOKEN = dev_token
	elif dev_token != '':
		push_warning("WARNING! Dev token will be ignored by the API because using Hathora Dev token on the client side is dangerous! See [to-do: link]")
