extends Node

const SWAGGER_URL: String = "https://hathora.dev/swagger.json"
const DEBUG_JSON_FILE_PATH: String = "res://addons/hathora_api/generator/_debug_swagger.json"
const Utils = preload("res://addons/hathora_api/generator/utils.gd")
const OpenApiSchema = GDSwagger.OpenApiSchema


static func load_api_schema(use_debug_file: bool = true) -> OpenApiSchema:
	var result: OpenApiSchema = OpenApiSchema.new()
	
	var raw_json: Dictionary
	# Step 0. Get json file with openapi schema
	if not use_debug_file:
		var response = await Hathora.Http.download_file_async(SWAGGER_URL)
		if response.error != Hathora.Error.Ok:
			push_error("Unexpected error while downloading API schema")
			breakpoint
		
		raw_json = response.data
	else:
		var file = FileAccess.open(DEBUG_JSON_FILE_PATH, FileAccess.READ)
		raw_json = Hathora.Http.json_parse_or(file.get_as_text(), {})
		file.close()
	
	if raw_json.is_empty():
		push_error("Unexpected error! Expected openapi json schema, but got nothing")
		breakpoint
	
	var raw_type_schemas: Dictionary = Utils.safe_get(
		raw_json, "components/schemas"
	)
	
	# Step 1. Parse raw types info
	for schema_name in raw_type_schemas.keys():
		result.types.push_back(GDSwagger.TypeSchema.parse(
			schema_name, raw_type_schemas
		))
	# Step 2. Parse raw endpoints info
	breakpoint
	
	return result
