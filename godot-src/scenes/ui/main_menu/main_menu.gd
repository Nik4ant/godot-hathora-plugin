extends Control

@onready var btn_create_lobby: Button = %btn_create_lobby
@onready var option_regions: OptionButton = %option_regions


func _ready() -> void:
	Hathora.init("app-b77567d4-9636-4755-a024-c50d01025ed6")
	# Signals
	btn_create_lobby.pressed.connect(_on_btn_create_lobby)


func _on_btn_create_lobby() -> void:
	# Get auth token
	var login_response = await Hathora.Auth.V1.login_anonymous_async()
	if login_response.error != Hathora.Error.Ok:
		print("Login error: ", login_response.error_message)
		return
	print("Auth token async: ", login_response.auth_token)
	
	# Create lobby
	var region: String = option_regions.get_item_text(option_regions.selected)
	var create_response = await Hathora.Lobby.V3.create_lobby_async(
		login_response.auth_token, "public", region
	)
	if create_response.error != Hathora.Error.Ok:
		print("Create lobby error: ", create_response.error_message)
		return
	print("Room id: ", create_response.lobby.room_id)
	
	# Get connection details
	var connection := await Hathora.Room.V2.get_connection_info_async(
		create_response.lobby.room_id
	)

	if connection.error != OK:
		print("Connection error: ", create_response.error_message)
		return
	print(connection.exposed_port.host, ':', connection.exposed_port.port)
