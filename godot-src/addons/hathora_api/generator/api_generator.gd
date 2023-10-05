const OUTPUT_FILENAME_TEMPLATE: String = "output/{name}.gd"

const Swagger = preload("res://addons/hathora_api/generator/swagger.gd")
const Utils = preload("res://addons/hathora_api/generator/utils.gd")
const KNOWN_TYPES: Dictionary = {
	"Lobby": "Lobby"
}
const DEFAULT_ASSERTS: Array[String] = [
	"assert(Hathora.APP_ID != '', \"ASSERT! Hathora MUST have a valid APP_ID. See init() function\")"
]
const SERVER_ASSERTS: Array[String] = [
	"assert(Hathora.assert_is_server(), '')"
]

enum AuthType {
	Dev,
	User,
	None
}

class ApiParam:
	var name: String
	var schema: Dictionary
	var required: bool
	
	func deserialize(data: Dictionary) -> void:
		assert(data.has("name"), "Missing field \"name\" in one of the parameter (unexpected)")
		assert(data.has("schema"), "Missing field \"schema\" in one of the parameter (unexpected)")
		assert(data.has("required"), "Missing field \"required\" in one of the parameter (unexpected)")
		self.name = data["name"]
		self.schema = data["schema"]
		self.required = bool(data["required"])


class EndpointInfo:
	var url: String							# (required)
	## v1 or v2
	var version: String						# (required)
	var name_snake_case: String				# (required)
	var name_PascalCase: String				# (required)
	var auth: AuthType						# (required)
	## List of params inside url like {appId} or {roomId} and etc.
	var path_params: Array[ApiParam]		# (optional)
	var query_params: Array[ApiParam]		# (optional)
	## get, post, update, delete
	var http_method: String					# (required)
	## Schema for a request body
	var request_body_schema: Dictionary 	# (optional)
	## List of all possible status codes
	var status_codes: Array[int]			# (optional)
	## All possible response schemas
	## key: status_code (int); value: schema (Dictionary)
	var response_schemas: Dictionary		# (required)


static func generate_api() -> void:
	var api_schema: Swagger.OpenApiSchema = await Swagger.load_api_schema()

#	for path in api_paths.keys():
#		var info: EndpointInfo = parse_endpoint_info(path, api_paths)
#		if info == null:
#			continue
#
#		var code: String = build_code(info, type_schemas)
#		print(code)


static func build_code(info: EndpointInfo, type_schemas: Dictionary) -> String:
	var gd = GD.Generator.new().add_comment(
		"region       -- " + info.name_snake_case
	)
	#region     -- Response class
	# Default fields
	var response_class = GD.GodotClass.create(
		info.name_PascalCase + "Response"
	).add_field(
		"error"
	).add_field(
		"error_message", GD.Types.GodotString
	)
	# Loading fields from successful response schema (if any)
	for status_code in info.response_schemas:
		if status_code < 300 and status_code >= 200:
			response_class = map_type_schema(
				info.response_schemas[status_code]["content"]["application/json"]["schema"], 
				type_schemas
			)
	
	var deserialize_func = GD.GodotFunction.create(
		"deserialize", GD.Types.Void
	).add_arg(
		"data", GD.Types.GodotDictionary
	)
	
	gd.add_class(
		response_class
	).add_function(
		deserialize_func
	)
	var warning_message: String = str(
		"WARNING! Deserialization code for ", response_class.name, 
		" was automatically generated and can be unstable"
	)
	gd.add_comment(
		"Note(api_generator.gd): THIS IS SUPER IMPORTANT!!!"
	).add_codeline(
		"push_warning(\"" + warning_message + "\")"
	)
	# Generate deserialization logic based on class fields
	for field in response_class.fields:
		_deserialize_code_for_field(gd, field, response_class.name)
	
	gd.end_func_decl().end_class_decl().add_newlines()
	#endregion  -- Response class
	
	
	#region     -- Async func
	var async_func = GD.GodotFunction.new()
	if info.auth == AuthType.User:
		async_func.add_arg("auth_token", GD.Types.GodotString)
	
	for param in info.request_body_schema.values():
		print("Request param: ", param)
	for query_param in info.query_params:
		(query_param as ApiParam)
		# TODO: MAKE SURE IT ACTUALLY WORKS
		var query_arg = GD.GodotFunctionArg.new()
		if query_param.required:
			query_arg.required = true
		else:
			pass
	# TODO: params + query params + path params that aren't constants (like ROOM_ID)
	# TODO: params + query params + path params that aren't constants (like ROOM_ID)
	# TODO: params + query params + path params that aren't constants (like ROOM_ID)
	gd.add_function(
		async_func
	)
	# Asserts
	for default_assert in DEFAULT_ASSERTS:
		gd.add_codeline(default_assert)
	if info.auth == AuthType.Dev:
		for server_only_assert in SERVER_ASSERTS:
			gd.add_codeline(server_only_assert)
	
	gd.add_var(GD.GodotVariable.create(
			"result", 
			response_class.self_type, 
			response_class.self_type.name + ".new()"
		)
	)
	# TODO: replace required path/url params either with consts
	var url_expression: String = info.url
	# (like APP_ID) or 
	gd.add_var(GD.GodotVariable.create(
			"url", 
			GD.Types.GodotString, 
			url_expression
		)
	)
	gd.add_comment("Api call")
	
	gd.add_newlines().add_codeline(
		"result.error = api_response.error"
	)
	# Check for errors
	gd.add_if(
		"api_response.error != Hathora.Error.Ok"
	).add_comment(
		"Note(api_generator.gd): THIS IS SUPER IMPORTANT!!!"
	).add_codeline(
		"push_warning(\"api_generator.gd CAN'T GENERATE CUSTOM ERRORS + HINTS!\")"
	).add_codeline(
		"result.error_message = Hathora.Error.push_default_or(api_response)"
	)
	# else deserialize
	gd.add_else().add_codeline(
		"result.deserialize(api_response.data)"
	).end_if_decl().add_newlines()
	# Emit signal and return
	gd.add_codeline(
		"HathoraEventBus.on_" + info.name_snake_case + ".emit()"
	).add_codeline(
		"return result"
	)
	gd.end_func_decl().add_newlines()
	#endregion  -- Async func
	
	
	#region     -- Sync func
	var sync_func = GD.GodotFunction.create(
		info.name_snake_case, GD.Types.GodotSignal
	).add_args(async_func.args)
	
	gd.add_function(
		sync_func
	).add_codeline(
		async_func.name + "(" + ", ".join(async_func.args) + ')'
	).add_codeline(
		"return HathoraEventBus.on_" + info.name_snake_case
	).end_func_decl()
	#endregion  -- Sync func
	
	gd.add_comment(
		"endregion     -- " + info.name_snake_case
	)
	return gd.build()


# TODO: explain
static func _deserialize_code_for_field(generator: GD.Generator, field: GD.GodotField, parent_name: String) -> void:
	var result: Array[String] = []
	
	if KNOWN_TYPES.has(field.type.name):
		generator.add_codeline(
			str(
				"self.", field.name, "= ", 
				field.type.name, ".deserialize(data)"
			)
		)
		return
	
	var name_from_schema: String = field.name.to_camel_case()
	# Assert
	generator.add_codeline(
		str(
			"assert(data.has(\"", name_from_schema, 
			"\"), ASSERT! Missing parameter \\\"", name_from_schema, 
			"\\\" in ", parent_name, " json \")"
		)
	)
	var de_codeline: String = "self." + field.name
	# Deserialize
	match field.type:
		# Arrays are a bit more tricky because inner type 
		# can be a class that needs to be deserialized
		GD.Types.GodotArray:
			# Note: The only types that aren't deserialized by default
			# are custom classes, which MUST have a static deserialize method
			if field.type.inner_sub_type == GD.Types.GodotClass:
				assert(KNOWN_TYPES.has(field.type.inner_sub_type.name), "Deserialization of Array sub type is impossible!")
				generator.add_for(
					"part", "data[\"" + name_from_schema + "\"]:"
				)
				de_codeline += str(
					".push_back(", field.type.inner_sub_type.name,
					".deserialize(part))"
				)
				generator.add_codeline(de_codeline)
				generator.end_for_decl()
		GD.Types.GodotInt:
			de_codeline += " = int(data[\"" + name_from_schema + "\"])"
			generator.add_codeline(de_codeline)
		_:
			de_codeline += " = data[\"" + name_from_schema + "\"]" 
			generator.add_codeline(de_codeline)


## Parses endpoint json, returns null if endpoint is deprecated
static func parse_endpoint_info(path: String, paths: Dictionary) -> EndpointInfo:
	var info: EndpointInfo = EndpointInfo.new()
		
	var http_methods: Array = paths[path].keys()
	assert(len(http_methods) == 1, "Same API endpoint can't accept different http methods (contact the dev)")
	info.http_method = http_methods[0]
	info.url = "https://api.hathora.dev" + path
	if "/v2/" in path:
		info.version = "v2"
	elif "/v1/" in path:
		info.version = "v1"
	else:
		push_error("Can't detect API version! (May occur if new version like v3 was added)")
		breakpoint
	
	var endpoint: Dictionary = paths[path][http_methods[0]]
	# Skip if deprecated
	if endpoint.get("deprecated", false):
		print("Skipping `", endpoint["operationId"], "` because it's deprecated")
		return null
	# Names
	info.name_PascalCase = endpoint["operationId"]
	info.name_snake_case = info.name_PascalCase.to_snake_case()
	# Auth (none + dev)
	info.auth = AuthType.None
	if len(Utils.safe_get(endpoint, "security")) != 0:
		info.auth = AuthType.Dev
	# Header + url + query params
	# Auth (user)
	for param in Utils.safe_get(endpoint, "parameters", []):
		assert(param.has("in"), "Unexpected `parameters` structure (contact the dev)")
		
		var param_info: ApiParam = ApiParam.new()
		param_info.deserialize(param)
		
		match param["in"]:
			"path":
				info.path_params.push_back(param_info)
			"header":
				if param_info.name == "Authorization" and param_info.required:
					info.auth = AuthType.User
			"query":
				info.query_params.push_back(param_info)
			_:
				push_error("Unknown \"in\" value inside parameters: `" + param["in"] + '`')
				breakpoint
	# Request body
	if Utils.safe_get(endpoint, "requestBody/required", false):
		info.request_body_schema = Utils.safe_get(
			endpoint, "requestBody-content-application/json-schema", 
			{}, '-'
		)
	# Responses, status codes
	var responses: Dictionary = endpoint.get("responses", {})
	for _status_code_str in responses.keys():
		var status_code: int = int(_status_code_str)
		info.status_codes.push_back(status_code)
		info.response_schemas[status_code] = responses[_status_code_str]
	
	return info


static func _get_type_schema(name: String, types_schemas: Dictionary) -> Dictionary:
	var raw_schema: Dictionary = types_schemas[name]
	var full_schema: Dictionary = raw_schema.get("properties", {})
	
	for property in full_schema.keys():
		# If property isn't a regular type load type info recursivly
		if full_schema[property].has("$ref"):
			full_schema[property] = _get_type_schema(
				full_schema[property]["$ref"], types_schemas
			)
	
	return full_schema


## Maps an API type schema to a Godot class
## [param type_schemas] - dictionary with all schemas defined by API spec
## [param schema_path] - path to a schema defined inside "$ref"
static func map_type_schema(schema_path: String, types_schemas: Dictionary) -> GD.GodotClass:
	var response_class = GD.GodotClass.new()
	
	# Step 1) Load schema info
	var key: String = schema_path.split('/')[-1]
	# If type is common (already defined somewhere) use it instead of
	# manually adding fields to mapped Godot class
	if KNOWN_TYPES.has(key):
		# Note(Nik4ant): It's inefficient to create GD.GodotType every
		# time, buuuut I'll leave it like this for now unless somebody
		# either fixes it OR points it out
		var custom_type = GD.GodotType.create(
			 KNOWN_TYPES[key], GD.Types.TypeId.Class
		)
		response_class.add_field(key.to_snake_case(), custom_type)
		return response_class
	# otherwise load types recursivly...
	var types: Dictionary = _get_type_schema(schema_path, types_schemas)
	
	# Step 2) Map schema types to Godot primitives + KNOWN_TYPES
	for field in types.keys():
		var type_info: Dictionary = types[field]
		var matched_type: GD.GodotType
		match type_info["type"]:
			"boolean":
				matched_type = GD.Types.GodotBool
			"integer":
				matched_type = GD.Types.GodotInt
			"string":
				matched_type = GD.Types.GodotString
			"array":
				matched_type = GD.Types.GodotArray
				push_warning("NOTE: Still have to determine the subtype somehow")
			"object":
				matched_type = GD.Types.GodotDictionary
			_:
				push_error("Can't map schema's type: `" + type_info["type"] + "` to Godot primitives")
				breakpoint
		
		response_class.add_field(field.to_snake_case(), matched_type)
	
	return response_class
