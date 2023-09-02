extends Control

# TODO: Turn HathoraError into an autoload maybe?
@onready var btn_create_lobby: Button = %btn_create_lobby


func _ready() -> void:
	HathoraClient.init("app-b77567d4-9636-4755-a024-c50d01025ed6")
	
	btn_create_lobby.pressed.connect(_on_btn_create_lobby)


func _on_btn_create_lobby():
	# Note: Typing won't work if = is used instead of :=
	# TODO: Change order of the call like this: await HathoraClient.Auth.V1
	# Note: Report progress to the Discord
	
	var login_response := await HathoraClient.V1.Auth.login_anonymous()
	if login_response.status != OK:
		print("_on_btn_create_lobby login error: ", login_response.error_message)
		return
	
	print(login_response.auth_token)
	
	var create_response := await HathoraClient.V2.Lobby.create(
		login_response.auth_token,
		"public",
		"Tokyo"
	)
	if create_response.status != OK:
		print("_on_btn_create_lobby create login error: ", create_response.error_message)
		return
	
	print(create_response.room_id)
