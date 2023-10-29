const OUTPUT_FILENAME_TEMPLATE: String = "res://addons/hathora_api/generator/output/{category}/{version}/{name}.gd"
const OUTPUT_FOLDER_TEMPLATE: String = "res://addons/hathora_api/generator/output/{category}/{version}"
const DEBUG_JSON_FILE_PATH: String = "res://addons/hathora_api/generator/_debug_swagger.json"
const SCHEMA_DOWNLOAD_URL: String = "https://hathora.dev/swagger.json"
## key - param_name: String; value - expression: String
## (param_name is in snake_case)
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
# Used to avoid preloading the same type twice
static var _preloaded_type_names: Array[String] = []


static func generate_api(use_debug_file: bool = false):
	_preloaded_type_names = []
	var raw_json: Dictionary
	# Step 0. Get openapi schema either from file or from the web
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
	# Step 1. Get schemas and endpoints
	var schemas_source: Dictionary = Utils.safe_get(
		raw_json, "components/schemas"
	)
	var paths: Dictionary = raw_json["paths"]
	const ENDPOINTS_EXCEPTIONS: Array[String] = [
		"/builds/v1/{appId}/run/{buildId}"
	]
	# Step 2. Generate code for each endpoint
	for path in paths:
		if ENDPOINTS_EXCEPTIONS.has(path):
			continue
		
		var endpoint: Endpoint = Endpoint.parse(
			path, paths[path], schemas_source
		)
		if endpoint.deprecated:
			print("Skipping `" + path + "` because it's deprecated")
			continue
		
		var code: String = build_code_for(endpoint)
		# Step 3. Save generated code
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


static func build_code_for(endpoint: Endpoint) -> String:
	var writer = GD.Writer.CodeWriter.new()
	
	if endpoint.tags:
		writer.comment(
			endpoint.tags[0],
			false
		).eol()
	writer.variable(Primitives.Variable.create(
		"ResponseJson", GD.Types.Dynamic, """preload("res://addons/hathora_api/core/http.gd").ResponseJson""",
		false, true
	)).eol().eol().eol()
	
	writer.comment(
		"region       -- " + endpoint.name_snake_case, true
	).eol()
	
	##region     -- Response class
	writer.class_decl(
		endpoint.name_PascalCase + "Response"
	).add_field(
		"error", GD.Types.Dynamic
	).add_field(
		"error_message", GD.Types.GodotString
	).eol(true)
	
	if endpoint.ok_response.schema:
		_build_response_class(writer, endpoint.ok_response.schema)
	
	var response_cls = writer.current_class
	writer.end_all()
	##endregion  -- Response class
	
	##region     -- Async func
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
		"HUMAN! I need your help - write error messages pls"
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
	##endregion  -- Async func
	
	##region     -- Sync func
	writer.func_decl(
		endpoint.name_snake_case, 
		GD.Types.GodotSignal, func_args, true, false
	)
	var func_args_names: Array[String] = []
	for arg in func_args:
		func_args_names.push_back(arg.name)
	writer.func_call(
		async_func, func_args_names
	).eol().codeline(
		"return HathoraEventBus.on_" + endpoint.name_snake_case
	)
	##endregion  -- Sync func
	
	writer.end_decl(false).comment(
		"endregion    -- " + endpoint.name_snake_case, true
	).eol()
	return writer.build()


static func _generate_args_for(endpoint: Endpoint) -> Array[GD.Primitives.FuncArg]:
	# (Not ideal, but reduses the amount of spagheti code anyway...)
	# Function args for specific endpoint can't have a class type,
	# so their type replaced with Dictionary
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
	
	return result


static func _build_response_class(writer: GD.Writer.CodeWriter, response_schema: GD.Swagger.Schema) -> void:
	if response_schema.is_flat:
		_preload_type_if_any(response_schema.flat.gd_type, writer)
		
		# If field is meant to represent time add "_unix" postfix
		if response_schema.flat.gd_type.id == GD.Types.Id.DateTime:
			writer.add_field(
				response_schema.flat.name_snake_case + "_unix", 
				response_schema.flat.gd_type
			)
		else:
			writer.add_field(
				response_schema.flat.name_snake_case,
				response_schema.flat.gd_type
			)
	else:
		for prop_name in response_schema.properties.keys():
			var value = response_schema.properties[prop_name]
			
			_preload_type_if_any(value.gd_type, writer)
			# If field is meant to represent time add "_unix" postfix
			if value.gd_type.id == GD.Types.Id.DateTime:
				writer.add_field(value.name_snake_case + "_unix", value.gd_type)
			else:
				writer.add_field(value.name_snake_case, value.gd_type)
	
	writer.eol(true)
	# Deserialize method
	var data_arg_type = GD.Types.dict()
	# In some rare cases endpoint can return flat number/string/array/etc
	# so in those cases type is different (the only exception to this list are)
	# classes...
	if (response_schema.is_flat 
			and response_schema.gd_type.id != GD.Types.Id.Class):
		# Note: If it's an array make sure it's `class` sub type 
		# is replaced with Dictionary
		if (response_schema.gd_type.id == GD.Types.Id.Array
				and response_schema.gd_type.value_sub_type.id == GD.Types.Id.Class):
			data_arg_type = GD.Types.array(GD.Types.dict())
		else:
			data_arg_type = response_schema.gd_type
	
	writer.add_method(
		"deserialize", GD.Types.Void, [
			GD.Primitives.FuncArg.create("data", data_arg_type, true)
		]
	)
	
	if response_schema.is_flat:
		_deserialization_for(response_schema.flat, writer)
	else:
		for property in response_schema.properties.values():
			_deserialization_for(property, writer)
			writer.eol(true)
	writer.code = writer.code.strip_edges(false)
	writer.eol().eol()


static func _deserialization_for(property, writer: GD.Writer.CodeWriter) -> void:
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
			writer.eol()
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


static func _preload_type_if_any(type: GD.Types.GodotType, writer: GD.Writer.CodeWriter) -> void:
	# If type is a class preload it
	if type.id == GD.Types.Id.Class:
		if _preloaded_type_names.has(type.name):
			return
		_preloaded_type_names.push_back(type.name)
		
		writer.insert_codeline(
			1,
			str(
				"const ", type.name, " = preload(\"res://addons/hathora_api/api/common_types.gd\").", 
				type.name
			)
		)
	# If either of the subtypes is a class preload them too
	else:
		if (GD.Types.GodotType._is_static(type.value_sub_type) 
				and type.value_sub_type.id == GD.Types.Id.Class):
			if _preloaded_type_names.has(type.value_sub_type.name):
				return
			_preloaded_type_names.push_back(type.value_sub_type.name)
		
			writer.insert_codeline(
				1,
				str(
					"const ", type.value_sub_type.name, " = preload(\"res://addons/hathora_api/api/common_types.gd\").", 
					type.value_sub_type.name
				)
			)
		
		if (GD.Types.GodotType._is_static(type.key_sub_type) 
				and type.key_sub_type.id == GD.Types.Id.Class):
			if _preloaded_type_names.has(type.key_sub_type.name):
				return
			_preloaded_type_names.push_back(type.key_sub_type.name)
			
			writer.insert_codeline(
				1,
				str(
					"const ", type.key_sub_type.name, " = preload(\"res://addons/hathora_api/api/common_types.gd\").", 
					type.key_sub_type.name
				)
			)
