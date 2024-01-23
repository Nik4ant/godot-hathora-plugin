## TL;DR
## * build_code_for - generates response class and sync + async calls
## * generate_api - puts everything together: downloading -> parsing -> saving
## * generate_common_types - generates all static types detected by _preload_type_if_any
const OUTPUT_FOLDER: String = "res://addons/hathora_api/generator/output"
const OUTPUT_FILENAME_TEMPLATE: String = OUTPUT_FOLDER + "/{category}/{version}/{name}.gd"
const OUTPUT_FOLDER_TEMPLATE: String = OUTPUT_FOLDER + "/{category}/{version}"
const DEBUG_JSON_FILE_PATH: String = "res://addons/hathora_api/generator/_debug_swagger.json"
const SCHEMA_DOWNLOAD_URL: String = "https://hathora.dev/swagger.json"

const KNOWN_CONSTANTS: Dictionary = {
	"appId": "Hathora.APP_ID"
}
const DEFAULT_ASSERTS: Array[String] = [
	"assert(Hathora.APP_ID != '', \"Hathora MUST have a valid APP_ID. See init() function\")"
]
const SERVER_ASSERTS: Array[String] = [
	"assert(Hathora.assert_is_server(), \"unreacheble\")"
]

const Utils = GD.Utils
const Primitives = GD.Primitives
const Endpoint = GD.Swagger.Endpoint
# Keeps track of ALL preloaded types
# (primarly for generating common_types.gd)
## type_name: String; schema: GD.Swagger.Schema
static var _preloaded_type_schemas: Dictionary = {}
# Keeps track of preloaded type names for current endpoint
static var _preloaded_types_current: Array[String] = []


static func generate_api(use_debug_file: bool = false):
	_preloaded_type_schemas = {}
	var raw_json: Dictionary
	# Get openapi schema either from file or from the web
	if use_debug_file:
		var file = FileAccess.open(DEBUG_JSON_FILE_PATH, FileAccess.READ)
		raw_json = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		var response = await Hathora.Http.download_file_async(SCHEMA_DOWNLOAD_URL)
		if response.error != Hathora.Error.Ok:
			push_error("Unexpected error while downloading API schema")
			breakpoint
		
		raw_json = response.data
	# Get schemas and endpoints
	var schemas_source: Dictionary = Utils.safe_get(
		raw_json, "components/schemas"
	)
	var paths: Dictionary = raw_json["paths"]
	const ENDPOINTS_EXCEPTIONS: Array[String] = [
		"/builds/v1/{appId}/run/{buildId}"
	]
	
	# Generate code for each endpoint
	for path in paths:
		_preloaded_types_current.clear()
		
		if ENDPOINTS_EXCEPTIONS.has(path):
			continue
		
		var endpoint: Endpoint = Endpoint.parse(
			path, paths[path], schemas_source
		)
		if endpoint.deprecated:
			print("Skipping `" + path + "` because it's deprecated")
			continue
		
		var code: String = build_code_for(endpoint)
		# Save generated code
		var category: String = endpoint.tags[0].to_lower().trim_suffix(endpoint.version)
		DirAccess.make_dir_recursive_absolute(OUTPUT_FOLDER_TEMPLATE.format({
				"category": category,
				"version": endpoint.version,
			})
		)
		var output_file = FileAccess.open(
			OUTPUT_FILENAME_TEMPLATE.format({
				"category": category,
				"version": endpoint.version,
				"name": endpoint.name_snake_case + '_' + endpoint.version
			}), FileAccess.WRITE
		)
		output_file.store_string(code)
		output_file.close()
		print("Done generating `", path, '`')
	
	#print("Generating common types...")
	#generate_common_types()


static func generate_common_types() -> void:
	var writer: GD.Writer.CodeWriter = GD.Writer.CodeWriter.new()
	
	# CRITICAL: It seems like using workaround with _build_response_class and
	# global _preloaded_type_schemas tracking produces giberish.
	# Option a) Rewrite _build_response_class
	# Option b) Generate only a list of decoys that human needs to implement
	# Option c) Screw this, no auto-generated common_types.gd I guess
	
	for type_name: String in _preloaded_type_schemas.keys():
		writer.class_decl(type_name)
		build_schema_based_class(writer, _preloaded_type_schemas[type_name])
		writer.end_all()
		writer.offset = 0
		print("Done generating `", type_name, '`')
	
	writer.build(OUTPUT_FOLDER + "/common_types.gd")


static func build_code_for(endpoint: Endpoint) -> String:
	var writer: GD.Writer.CodeWriter = GD.Writer.CodeWriter.new()
	
	if endpoint.tags:
		writer.comment(endpoint.tags[0]).eol()
	
	writer.variable(Primitives.Variable.create(
		"ResponseJson", GD.Types.Dynamic, """preload("res://addons/hathora_api/core/http.gd").ResponseJson""",
		false, true
	)).eol().eol().eol()
	
	writer.comment(
		"region       -- " + endpoint.name_snake_case, false
	).eol()
	
	#region     -- Response class
	writer.class_decl(
		endpoint.name_PascalCase + "Response"
	).add_field(
		"error", GD.Types.Dynamic
	).add_field(
		"error_message", GD.Types.GodotString
	).eol(true)
	
	if endpoint.ok_response.schema:
		_preload_common_types(writer, endpoint.ok_response.schema)
		build_schema_based_class(writer, endpoint.ok_response.schema)
	else:
		writer.code = writer.code.strip_edges(false)
		writer.eol()
	
	var response_cls = writer.current_class
	writer.end_all()
	#endregion  -- Response class
	
	#region     -- Async func
	var func_args: Array[GD.Primitives.FuncArg] = _generate_args_for(endpoint)
	writer.func_decl(
		endpoint.name_snake_case + "_async", 
		response_cls.type, func_args, true, true
	)
	# Default + dev asserts
	for assertation in DEFAULT_ASSERTS:
		writer.codeline(assertation)
	if endpoint.security.has(GD.Swagger.Security.Dev):
		for assertation in SERVER_ASSERTS:
			writer.codeline(assertation)
	# Special asserts that exists only for "certain" enums
	if writer.current_func._has_arg_with_name("region"):
		writer.codeline(
			"assert(Hathora.REGIONS.has(region), \"Region `\" + region + \"` doesn't exists\")"
		)
	if writer.current_func._has_arg_with_name("visibility"):
		writer.codeline(
			"assert(Hathora.VISIBILITIES.has(visibility), \"Visibility `\" + visibility + \"` doesn't exists\")"
		)
	writer.eol(true)
	
	# result var
	writer.variable(GD.Primitives.Variable.create(
		"result", response_cls.type, response_cls.name + ".new()"
	)).eol()
	# endpoint params
	var query_params_exprs: Dictionary = {}
	var path_expressions: Dictionary = {}
	for param in endpoint.params:
		if param.location == GD.Swagger.Location.Query:
			query_params_exprs['"' + param.name_default + '"'] = param.name_snake_case
		elif param.location == GD.Swagger.Location.Path:
			if KNOWN_CONSTANTS.has(param.name_default):
				path_expressions['"' + param.name_default + '"'] = KNOWN_CONSTANTS[param.name_default]
			else:
				path_expressions['"' + param.name_default + '"'] = param.name_snake_case
	# Url variable decl
	writer.variable(GD.Primitives.Variable.create(
		"url", GD.Types.GodotString, 
		"\"https://api.hathora.dev" + endpoint.path + '\"'
	))
	# Url path params
	if not path_expressions.is_empty():
		writer.expr(".format(").eol().dict_expr(
			path_expressions, true, 1
		).eol().codeline(')')
	else:
		writer.eol()
	# Url query params
	if not query_params_exprs.is_empty():
		writer.codeline(
			"url += Hathora.Http.build_query_params("
		).dict_expr(
			query_params_exprs, true, 1
		).eol().codeline(')')
	
	writer.comment("Api call").eol()
	# Headers
	var headers_expr: String = "[\"Content-Type: application/json\""
	if endpoint.security.has(GD.Swagger.Security.Auth):
		headers_expr += ", \"Authorization: \" + auth_token"
	elif endpoint.security.has(GD.Swagger.Security.Dev):
		headers_expr += ", Hathora.DEV_AUTH_HEADER"
	headers_expr += ']'
	if endpoint.body:
		headers_expr += ','
	
	writer.variable(GD.Primitives.Variable.create(
		"api_response", GD.Types.class_("ResponseJson"),
		str(
			"await Hathora.Http.", endpoint.http_method, "_async("
		)
	)).eol().codeline("\turl,").codeline('\t' + headers_expr)
	# Request body
	if endpoint.body:
		var body_schema = endpoint.body.schema
		var body_exprs: Dictionary = {}
		if endpoint.body.schema.is_flat:
			body_exprs['"' + body_schema.flat.name_default + '"'] = body_schema.flat.name_snake_case
		else:
			for prop in body_schema.properties.values():
				body_exprs['"' + prop.name_default + '"'] = prop.name_snake_case
		writer.dict_expr(body_exprs, true, 1).eol()
	# If body schema is empty, but method is post,
	# send nothing/empty dict
	elif endpoint.http_method == "post":
		writer.codeline(", {}").eol()
	writer.codeline(')')
	
	writer.comment("Api errors").eol().codeline(
		"result.error = api_response.error"
	).if_statement(
		"result.error != Hathora.Error.Ok"
	).comment(
		"WARNING: HUMAN! I need your help - write custom error messages"
	).eol().comment(
		"List of error codes: " + str(endpoint.error_responses.keys())
	).eol().codeline(
		"result.error_message = Hathora.Error.push_default_or("
	).codeline(
		"\tapi_response, {}"
	).codeline(')')
	# If there is anything to deserialize...
	if len(response_cls.fields) > 2:
		writer.else_statement().codeline(
			"result.deserialize(api_response.data)"
		)
	writer.end_statement()
	
	writer.codeline(str(
		"HathoraEventBus.on_", endpoint.name_snake_case, 
		".emit(result)"
	)).codeline("return result")
	
	var async_func = writer.current_func
	writer.end_decl().eol()
	#endregion  -- Async func
	
	#region     -- Sync func
	writer.func_decl(
		endpoint.name_snake_case, 
		GD.Types.GodotSignal, async_func.args, true, false
	)
	
	var func_args_names: Array[String] = []
	for arg in func_args:
		func_args_names.push_back(arg.name)
	writer.func_call(
		async_func, func_args_names
	).eol().codeline(
		"return HathoraEventBus.on_" + endpoint.name_snake_case
	)
	#endregion  -- Sync func
	
	writer.end_decl(false).comment(
		"endregion    -- " + endpoint.name_snake_case, false
	).eol()
	return writer.build()


static func _preload_common_types(writer: GD.Writer.CodeWriter, schema: GD.Swagger.Schema) -> void:
	var _insert_preload_statement: Callable = func(type_name: String) -> void:
		writer.insert_codeline(
			1,
			str(
				"const ", type_name, " = preload(\"res://addons/hathora_api/api/common_types.gd\").", 
				type_name
			)
		)
	
	var _preload_type_if_any: Callable = func(type: GD.Types.GodotType) -> void:
		# Type itself
		if (!_preloaded_types_current.has(type.name) and 
				type.id == GD.Types.Id.Class):
			_preloaded_type_schemas[type.name] = schema
			_preloaded_types_current.push_back(type.name)
			_insert_preload_statement.call(type.name)
		# Subtypes (if any)
		else:
			if (type.value_sub_type != null and 
					!_preloaded_types_current.has(type.value_sub_type.name) and
					type.value_sub_type.id == GD.Types.Id.Class):
				_preloaded_type_schemas[type.value_sub_type.name] = schema
				_preloaded_types_current.push_back(type.value_sub_type.name)
				_insert_preload_statement.call(type.value_sub_type.name)
			
			if (type.key_sub_type != null and 
					!_preloaded_types_current.has(type.key_sub_type.name) and 
					type.key_sub_type.id == GD.Types.Id.Class):
				_preloaded_type_schemas[type.key_sub_type.name] = schema
				_preloaded_types_current.push_back(type.key_sub_type.name)
				_insert_preload_statement.call(type.key_sub_type.name)
	
	if schema.is_flat:
		_preload_type_if_any.call(schema.flat.gd_type)
	else:
		for prop_name in schema.properties.keys():
			var value = schema.properties[prop_name]
			_preload_type_if_any.call(value.gd_type)

## (assumes class is already declared by [param writer])
static func build_schema_based_class(writer: GD.Writer.CodeWriter, schema: GD.Swagger.Schema) -> void:
	assert(writer.current_class != null, "No target class to build!")
	
	#region Fields
	if schema.is_flat:
		# Specify time format for clarity
		if schema.flat.gd_type.id == GD.Types.Id.DateTime:
			schema.add_field(
				schema.flat.name_snake_case + "_unix", schema.flat.gd_type
			)
		else:
			writer.add_field(
				schema.flat.name_snake_case, schema.flat.gd_type
			)
	else:
		for prop_name in schema.properties.keys():
			var value = schema.properties[prop_name]
			# Specify time format for clarity
			if value.gd_type.id == GD.Types.Id.DateTime:
				writer.add_field(value.name_snake_case + "_unix", value.gd_type)
			else:
				writer.add_field(value.name_snake_case, value.gd_type)
	#endregion
	
	if writer.current_class.fields.size() > 2 or writer.current_class.fields.size() == 1:
		writer.eol(true)
	#region deserialize(data)
	var data_arg_type = GD.Types.dict()
	
	if (schema.is_flat and schema.gd_type.id != GD.Types.Id.Class):
		# By default parser gives specific types and subtypes.
		# in the deserialization context type info doesn't exist, so
		# classes are replaced with Dictionary (json) =
		if (schema.gd_type.id == GD.Types.Id.Array
				and schema.gd_type.value_sub_type.id == GD.Types.Id.Class):
			data_arg_type = GD.Types.array(GD.Types.dict())
		# number/string/array/etc.
		else:
			data_arg_type = schema.gd_type
	
	writer.add_method(
		"deserialize", GD.Types.Void, [
			GD.Primitives.FuncArg.create("data", data_arg_type, true)
		]
	)
	
	if schema.is_flat:
		_build_property_desirialization(schema.flat, writer)
	else:
		for property in schema.properties.values():
			_build_property_desirialization(property, writer)
			writer.eol(true)
	#endregion
	writer.code = writer.code.strip_edges(false)
	writer.eol().eol()

#region Helper functions
static func _generate_args_for(endpoint: Endpoint) -> Array[GD.Primitives.FuncArg]:
	# If object resembles a known type, Dictionary still must be used
	# (primarly as an API param)
	var _validate_arg_type = func _lambda(type: GD.Types.GodotType) -> GD.Types.GodotType:
		if type.id == GD.Types.Id.Class:
			return GD.Types.dict()
		return type
	
	var result: Array[GD.Primitives.FuncArg] = []
	
	if endpoint.security.has(GD.Swagger.Security.Auth):
		result.push_back(GD.Primitives.FuncArg.create(
			"auth_token", GD.Types.GodotString, true
		))
	
	# Request body args
	if endpoint.body:
		var body_schema = endpoint.body.schema
		if body_schema.is_flat:
			result.push_back(GD.Primitives.FuncArg.create(
				body_schema.flat.name_snake_case,
				_validate_arg_type.call(body_schema.flat.gd_type),
				body_schema.required
			))
		else:
			for property in body_schema.properties.values():
				result.push_back(GD.Primitives.FuncArg.create(
					property.name_snake_case,
					_validate_arg_type.call(property.gd_type),
					body_schema.required.has(property.name_default)
				))
	# Parameters
	for param in endpoint.params:
		# If value is a constant no need to pass it as an arg
		if KNOWN_CONSTANTS.has(param.name_default):
			continue
		
		result.push_back(GD.Primitives.FuncArg.create(
			param.name_snake_case,
			param.schema.gd_type,
			param.required
		))
	
	result.sort_custom(
		func(a: GD.Primitives.FuncArg, b: GD.Primitives.FuncArg) -> bool:
			return not b.required
	)
	return result


## TODO: explain
## TL;DR sourse_data_type - type of the data param in the deserialize function
static func _build_property_desirialization(property, writer: GD.Writer.CodeWriter) -> void:
	if property.name_default != '':
		writer.codeline(str(
			"assert(data.has(\"", property.name_default, 
			"\"), \"Missing parameter \\\"", property.name_default,
			"\\\"\")"
		))
	
	match property.gd_type.id:
		GD.Types.Id.Class:
			writer.codeline(str(
					"self.", property.name_snake_case,
					" = ", property.gd_type.name, ".deserialize(data[\"",
					property.name_default, "\"])"
				)
			)
		GD.Types.Id.DateTime:
			writer.codeline(str(
					"self.", property.name_snake_case, 
					"_unix = Time.get_unix_time_from_datetime_string(data[\"",
					property.name_default, "\"])"
				)
			)
		GD.Types.Id.Array:
			var prop_name: String = "result"
			if property.name_snake_case != '':
				prop_name = property.name_snake_case
				writer.for_statement(
					"part", "data[\"" + property.name_default + '"]'
				)
			else:
				writer.for_statement(
					"part", "data"
				)
			
			# If sub type is a class - deserialize it
			if property.gd_type.value_sub_type.id == GD.Types.Id.Class:
				writer.codeline(str(
					"self.", prop_name, ".push_back(", 
					property.gd_type.value_sub_type.name, ".deserialize(part))"
				))
			# Otherwise just append
			else:
				writer.codeline(str(
					"self.", prop_name, ".push_back(part)"
				))
			writer.offset -= 1
		_:
			# TODO: explanation
			# TL;DR Some endpoints return flat string/number or whatever
			# That's why there is no propery name
			if property.name_default == '':
				writer.codeline("self.result = data")
			else:
				writer.codeline(str(
						"self.", property.name_snake_case,
						" = data[\"", property.name_default, "\"]"
					)
				)
#endregion
