@tool
extends EditorPlugin


const AUTOLOADS: Array = [
	["Hathora", "res://addons/hathora_api/HathoraClient.tscn"],
	["HathoraEventBus", "res://addons/hathora_api/core/HathoraEventBus.gd"],
	# NOTE: For api generation only!
	["GD", "res://addons/hathora_api/generator/gd/gd.gd"],
]
const openapi := preload("res://addons/hathora_api/generator/api_generator.gd")
const TOOL_MENU_ITEM: String = "Generate Hathora Api"


func _enter_tree() -> void:
	for autoload in AUTOLOADS:
		add_autoload_singleton(autoload[0], autoload[1])
	
	init_http()
	add_tool_menu_item(TOOL_MENU_ITEM, openapi.generate_api)


func _exit_tree() -> void:
	for autoload in AUTOLOADS:
		remove_autoload_singleton(autoload[0])
	
	deinit_http()
	remove_tool_menu_item(TOOL_MENU_ITEM)


#region Http
func init_http() -> void:
	var http: HTTPRequest = HTTPRequest.new()
	get_editor_interface().get_base_control().add_child(http)
	Hathora.Http.init(http)

func deinit_http() -> void:
	get_editor_interface().get_base_control().remove_child(Hathora.Http.http_node)
#endregion
