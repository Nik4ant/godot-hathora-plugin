@tool
extends EditorPlugin


const AUTOLOADS: Array = [
	["Hathora", "res://addons/hathora_api/HathoraClient.tscn"],
	["HathoraEventBus", "res://addons/hathora_api/HathoraEventBus.gd"]
]


func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		add_autoload_singleton(autoload[0], autoload[1])


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload[0])
