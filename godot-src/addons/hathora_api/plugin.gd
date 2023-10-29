@tool
extends EditorPlugin


const AUTOLOADS: Array = [
	["Hathora", "res://addons/hathora_api/HathoraClient.tscn"],
	["HathoraEventBus", "res://addons/hathora_api/core/HathoraEventBus.gd"]
]


func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		add_autoload_singleton(autoload[0], autoload[1])
	# TODO: add a separate setting or smth
	add_autoload_singleton(
		"GD", "res://addons/hathora_api/generator/gd/gd.gd"
	)


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload[0])
	remove_autoload_singleton("GD")
