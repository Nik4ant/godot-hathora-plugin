extends Control

@onready var btn_create_lobby: Button = %btn_create_lobby
@onready var option_regions: OptionButton = %option_regions


func _ready() -> void:
	HathoraClient.init("app-6f99cf8f-8e3c-4518-b24c-48ca3ea0da0f")
	# Signals
	btn_create_lobby.pressed.connect(_on_btn_create_lobby)


func _on_btn_create_lobby():
	var login_response = await HathoraClient.Auth.V1.login_anonymous()
	if login_response.status != OK:
		print("_on_btn_create_lobby login error: ", login_response.error_message)
		return
	print("Auth token: ", login_response.auth_token)
	
	var region: String = option_regions.get_item_text(option_regions.selected)
	var create_response = await HathoraClient.Lobby.V2.create(
		login_response.auth_token, "public", region
	)
	if create_response.status != OK:
		print("_on_btn_create_lobby create login error: ", create_response.error_message)
		return
	print("Room id: ", create_response.room_id)
