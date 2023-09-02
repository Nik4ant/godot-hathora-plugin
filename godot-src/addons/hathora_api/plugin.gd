@tool
extends EditorPlugin

const AUTOLOAD_CLIENT_NAME: String = "HathoraClient"
const AUTOLOAD_CLIENT_PATH: String = "res://addons/hathora_api/HathoraClient.tscn"

const AUTOLOAD_CONSTANTS_NAME: String = "HathoraConstants"
const AUTOLOAD_CONSTANTS_PATH: String = "res://addons/hathora_api/HathoraConstants.gd"


func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_CLIENT_NAME, AUTOLOAD_CLIENT_PATH)
	add_autoload_singleton(AUTOLOAD_CONSTANTS_NAME, AUTOLOAD_CONSTANTS_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_CLIENT_NAME)
	remove_autoload_singleton(AUTOLOAD_CONSTANTS_NAME)
