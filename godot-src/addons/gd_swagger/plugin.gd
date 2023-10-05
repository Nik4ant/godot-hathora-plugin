@tool
extends EditorPlugin


const AUTOLOADS: Array = [
	["GD", "res://addons/gd_swagger/gd_generator/gdscript.gd"],
	["GDSwagger", "res://addons/gd_swagger/swagger/swagger.gd"]
]

func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		add_autoload_singleton(autoload[0], autoload[1])


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload[0])
