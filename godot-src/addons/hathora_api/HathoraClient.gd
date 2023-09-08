extends Node

@onready var http_request: HTTPRequest = $http

#region     -- Configuration
@export var APP_ID: String = ''
## Is current instance running on the server OR on the client
@export var is_client: bool = false
## Dev token for Hathora API
## (Exists ONLY IF is_client is false, meaning it's server-side)
@export var DEV_TOKEN: String = ''
#endregion  -- Configuration


## Initiailizes
func init(app_id: String, is_client: bool = true, dev_token: String = '') -> void:
	if self.APP_ID != '':
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


##region     -- Endpoints
const App := preload("res://addons/hathora_api/api/app/app.gd")
const Auth := preload("res://addons/hathora_api/api/auth/auth.gd")
const Billing := preload("res://addons/hathora_api/api/billing/billing.gd")
const Build := preload("res://addons/hathora_api/api/build/build.gd")
const Deployment := preload("res://addons/hathora_api/api/deployment/deployment.gd")
const Discovery := preload("res://addons/hathora_api/api/discovery/discovery.gd")
const Lobby := preload("res://addons/hathora_api/api/lobby/lobby.gd")
const Log := preload("res://addons/hathora_api/api/log/log.gd")
const Managment := preload("res://addons/hathora_api/api/managment/managment.gd")
const Metrics := preload("res://addons/hathora_api/api/metrics/metrics.gd")
const Processes := preload("res://addons/hathora_api/api/processes/processes.gd")
const Room := preload("res://addons/hathora_api/api/room/room.gd")
#endregion   -- Endpoints
