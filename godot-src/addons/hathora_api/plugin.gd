@tool
extends EditorPlugin


const AUTOLOADS: Array = [
	["HathoraClient", "res://addons/hathora_api/HathoraClient.tscn"],
	["HathoraConstants", "res://addons/hathora_api/HathoraConstants.gd"],
	["HathoraEventBus", "res://addons/hathora_api/HathoraEventBus.gd"]
]


func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		add_autoload_singleton(autoload[0], autoload[1])


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload[0])
