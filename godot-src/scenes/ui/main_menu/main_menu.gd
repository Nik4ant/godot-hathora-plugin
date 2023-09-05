extends Control

@onready var btn_create_lobby: Button = %btn_create_lobby
@onready var option_regions: OptionButton = %option_regions


func _ready() -> void:
	HathoraClient.init("app-b77567d4-9636-4755-a024-c50d01025ed6")
	# Signals
	btn_create_lobby.pressed.connect(_on_btn_create_lobby)


func _on_btn_create_lobby():
	# Get auth token
	var login_response = await HathoraClient.Auth.V1.login_anonymous()
	if login_response.error != OK:
		print("Login error: ", login_response.error_message)
		return
	print("Auth token: ", login_response.auth_token)
	
	# Create lobby
	var region: String = option_regions.get_item_text(option_regions.selected)
	var create_response = await HathoraClient.Lobby.V2.create(
		login_response.auth_token, "public", region
	)
	if create_response.error != OK:
		print("Create lobby error: ", create_response.error_message)
		return
	print("Room id: ", create_response.room_id)
	
	# Get connection details
	var connection := await HathoraClient.Room.V2.get_connection_info(
		create_response.room_id
	)
	
	if connection.error != OK:
		print(": ", create_response.error_message)
		return
	print(connection.exposed_port.host, ':', connection.exposed_port.port)


func example_async():
	# TODO:
	pass

func example_sync():
	HathoraClient.Auth.V1.login_anonymous_sync()
