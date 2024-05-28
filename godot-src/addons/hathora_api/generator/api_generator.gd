const ApiEndpoint = GD.Swagger.ApiEndpoint
const Schema = GD.Swagger.Schema

const GENERATOR_OUTPUT_FOLDER: String = "res://addons/hathora_api/generator/output/"
const COMMON_TYPES_PATH: String = GENERATOR_OUTPUT_FOLDER + "/common_types.gd"
const EVENT_BUS_PATH: String = GENERATOR_OUTPUT_FOLDER + "/HathoraEventBus.gd"
const OUTPUT_FOLDER: String = GENERATOR_OUTPUT_FOLDER + "/{category}/{version}"
const OUTPUT_SPECIFIC_FILENAME: String = GENERATOR_OUTPUT_FOLDER + "/{category}/{version}/{category}_{version}.gd"
const OUTPUT_GENERAL_FILENAME: String = GENERATOR_OUTPUT_FOLDER + "/{category}/{category}.gd"
const DEBUG_JSON_FILE_PATH: String = "res://addons/hathora_api/generator/_debug_swagger.json"
const SCHEMA_DOWNLOAD_URL: String = "https://hathora.dev/swagger.json"
const ENDPOINTS_EXCEPTIONS: Array[String] = [
	"/builds/v1/{appId}/run/{buildId}"
]
# NOTE: If those are used somewhere else, change this to a 
# Dictionary with custom names
const COMMON_TYPES_SCHEMAS_EXCEPTIONS: Array[String] = [
	"Partial__card-CardPaymentMethod--ach-AchPaymentMethod--link-LinkPaymentMethod--__",
	"Record_Partial_MetricName_.MetricValue-Array_",
	"Pick_Room.Exclude_keyofRoom.allocations__",
	"Omit_Room.allocations_",
	"Record_string.never_"
]

const KNOWN_CONSTANTS: Dictionary = {
	"appId": "Hathora.APP_ID"
}
const DEFAULT_ASSERTS: Array[String] = [
	"assert(Hathora.APP_ID != '', \"Hathora MUST have a valid APP_ID. See init() function\")"
]

const SERVER_ASSERTS: Array[String] = [
	"assert(Hathora.assert_is_server(), \"unreacheble\")"
]
## Contains all preloaded types for current script (cleared every time)
static var preloaded_types: Dictionary = {}
static var event_bus_script_writer: GD.Writer


static func generate_api(use_debug_file: bool = false) -> void:
	event_bus_script_writer = GD.Writer.new()
	event_bus_script_writer.codeline("extends Node").eol()
	var full_json: Dictionary
	
	#region Get json schema
	if use_debug_file:
		var file = FileAccess.open(DEBUG_JSON_FILE_PATH, FileAccess.READ)
		full_json = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		full_json = (await Hathora.Http.download_file_async(SCHEMA_DOWNLOAD_URL)).data
	#endregion
	## Dictionary[String, Schema]
	var common_class_types: Dictionary = {}
	var common_types_writer: GD.Writer = GD.Writer.new()
	#region Parse schemas + common_types.gd
	var all_schemas_json: Dictionary = GD.Utils.safe_get(
		full_json, "components/schemas"
	)
	
	for schema_name: String in all_schemas_json.keys():
		if (COMMON_TYPES_SCHEMAS_EXCEPTIONS.has(schema_name) or
				common_class_types.has(schema_name) or schema_name.ends_with("Response") 
				or schema_name.ends_with("Params") or schema_name.ends_with("Request")):
			continue
		
		var schema: Schema = GD.Swagger.swagger_schema_to_gd(schema_name, all_schemas_json)
		
		if !schema.deprecated and schema.type.id == GD.Types.Id.Class:
			common_class_types[schema_name] = generate_response_for(schema, false, common_types_writer)
			common_types_writer.eol().eol()
	
	common_types_writer.finish(COMMON_TYPES_PATH)
	#endregion
	
	## Dictionary[String, Dictionary[String, Array[ApiEndpoint]]]
	var categorized_endpoints: Dictionary = {}
	#region Parse paths
	var raw_paths_json: Dictionary = full_json["paths"]
	for url: String in raw_paths_json.keys():
		if ENDPOINTS_EXCEPTIONS.has(url):
			continue
		
		var path_json: Dictionary = raw_paths_json[url]
		var endpoint: ApiEndpoint = ApiEndpoint.from_json(url, path_json, all_schemas_json)
		
		if endpoint.deprecated:
			continue
		
		# Sort endpoints based on group and version
		if categorized_endpoints.has(endpoint.group_name):
			if !categorized_endpoints[endpoint.group_name].has(endpoint.version):
				categorized_endpoints[endpoint.group_name] = { endpoint.version: [] }
			
			categorized_endpoints[endpoint.group_name][endpoint.version].push_back(endpoint)
		else:
			categorized_endpoints[endpoint.group_name] = {
				endpoint.version: [endpoint]
			}
	#endregion
	
	#region Generate paths
	for category: String in categorized_endpoints.keys():
		var category_writer: GD.Writer = GD.Writer.new().comment(category, true).eol()
		var versions: Dictionary = categorized_endpoints[category]
		
		for version: String in versions.keys():
			var filename: String = OUTPUT_SPECIFIC_FILENAME.format(
				{ "category": category, "version": version }
			)
			category_writer.add_var(
				GD.Types.GodotVariable.new(
					version.to_upper(), GD.Types.class_("Script"), 
					false, true, 'preload("' + filename + '")'
				)
			)
			var api_writer: GD.Writer = GD.Writer.new()
			generate_api_group(category, version, versions[version], api_writer)
			api_writer.finish(filename)
		category_writer.finish(OUTPUT_GENERAL_FILENAME.format({"category": category}))
	#endregion
	
	event_bus_script_writer.finish(EVENT_BUS_PATH)


#region Generation utils
static func _preload_type(type_name: String, writer: GD.Writer) -> void:
	writer.insert_codeline(
		1,
		str(
			"const ", type_name, 
			' = preload("res://addons/hathora_api/api/common_types.gd").',
			type_name
		)
	)

static func _format_doc_comment(raw_comment: String, writer: GD.Writer) -> String:
	return raw_comment.replace("\n\n", '\n').replace("\n", "\n" + writer._offset() + "## ")

static func _get_data_arg_type_for(schema: Schema) -> GD.Types.GodotType:
	# data arg type represents a parsed json, so:
	# - Class is replaced with Dictionary
	var data_json_type: GD.Types.GodotType
	
	if schema.type.id == GD.Types.Id.Class:
		data_json_type = GD.Types.dict()
	elif schema.type.id == GD.Types.Id.Array:
		if schema.type.sub_type_value.id == GD.Types.Id.Class:
			data_json_type = GD.Types.array(GD.Types.dict())
		else:
			data_json_type = GD.Types.array(schema.type.sub_type_value)
	else:
		data_json_type = schema.type
	
	return data_json_type

## Generates deserialization code for signle property
static func _deserialize_property_from_data_json(
			target_object: String, name_snake: String, property: GD.Types.GodotTypeProperty, 
			data_json_type: GD.Types.GodotType, 
			writer: GD.Writer) -> void:
		
		var nameCamel: String = name_snake.to_camel_case()
		var json_value_expr: String = 'data["' + nameCamel + '"]'
		#region Array
		if property.type.id == GD.Types.Id.Array:
			var item_type: GD.Types.GodotType
			#region Sub type
			if property.type.sub_type_value.id == GD.Types.Id.Class:
				# Class with only 1 Array field
				if property.type.properties.size() == 1 and property.type.properties.has("result"):
					# NOTE: Array of Dictionary because nested arrays are not supported
					# by schema
					item_type = GD.Types.array(GD.Types.dict())
				else:
					item_type = GD.Types.dict()
			else:
				item_type = property.type.sub_type_value
			#endregion
			
			writer.for_in(
				"item",
				GD.Types.TypedExpr.new(json_value_expr, property.type),
				item_type
			).eol().codeline(target_object + '.' + name_snake, false)
			
			match property.type.sub_type_value.id:
				GD.Types.Id.Class:
					writer.raw_expr(".push_back(" + property.type.sub_type_value.name + ".deserialize(item))")
				GD.Types.Id.DateTime:
					writer.raw_expr(
						"_unix.push_back(Time.get_unix_time_from_datetime_string(item))"
					)
				GD.Types.Id.Int:
					writer.raw_expr(".push_back(int(item))")
				GD.Types.Id.Float:
					writer.raw_expr(".push_back(float(item))")
				_:
					writer.raw_expr(".push_back(item)")
			
			writer.end().eol()
		#endregion
		#region Datetime
		elif property.type.id == GD.Types.Id.DateTime:
			writer.codeline(
				target_object + '.' + name_snake + "_unix = ", false
			).raw_expr(
				"Time.get_unix_time_from_datetime_string(" + json_value_expr + ')'
			).eol()
		#endregion
		else:
			writer.codeline(target_object + '.' + name_snake + " = ", false)
			
			#region Class
			if property.type.id == GD.Types.Id.Class:
				writer.call_unsafe(
					property.type.name + ".deserialize",
					[json_value_expr]
				)
			#endregion
			#region Other
			else:
				match property.type.id:
					GD.Types.Id.Int:
						writer.raw_expr("int(" + json_value_expr + ')')
					GD.Types.Id.Float:
						writer.raw_expr("float(" + json_value_expr + ')')
					_:
						writer.raw_expr(json_value_expr)
			#endregion
			writer.eol()

## Sometimes GD type MUST be JSON (api) compatible
static func __format_type_to_fit_json(type: GD.Types.GodotType) -> GD.Types.GodotType:
	if type.id == GD.Types.Id.Class:
		return GD.Types.dict()
	if type.id == GD.Types.Id.Array:
		return GD.Types.array(__format_type_to_fit_json(type.sub_type_value))
	if type.id == GD.Types.Id.Dict:
		return GD.Types.dict(
			__format_type_to_fit_json(type.sub_type_key),
			__format_type_to_fit_json(type.sub_type_value),
		)
	
	return type

static func _generate_func_args_for(endpoint: ApiEndpoint) -> Array[GD.Types.GodotFunctionArg]:
	var result: Array[GD.Types.GodotFunctionArg] = []
	
	if endpoint.security.has(ApiEndpoint.Security.User):
		result.push_back(GD.Types.GodotFunctionArg.new(
			"auth_token", GD.Types.String_
		))
	
	#region Request body
	if endpoint.request_body != null:
		var body_schema: GD.Swagger.Schema = endpoint.request_body.schema
		
		for name: String in body_schema.type.properties.keys():
			var property: GD.Types.GodotTypeProperty = body_schema.type.properties[name]
			
			result.push_back(GD.Types.GodotFunctionArg.new(
				name, 
				__format_type_to_fit_json(property.type), 
				property.required
			))
	#endregion
	
	#region Url params
	for target: Dictionary in [endpoint.path_params, endpoint.query_params]:
		for name: String in target.keys():
			if KNOWN_CONSTANTS.has(name):
				continue

			var url_param: GD.Swagger.ApiEndpointUrlParam = target[name]
			result.push_back(GD.Types.GodotFunctionArg.new(
				url_param.name_snake, 
				__format_type_to_fit_json(url_param.schema.type), 
				url_param.required
			))
	#endregion
	
	return result
#endregion


#region Main
static func _observe_type_for_preload(type: GD.Types.GodotType, writer: GD.Writer) -> void:
	if type.id == GD.Types.Id.Class:
		if not preloaded_types.has(type.name):
			preloaded_types[type.name] = type
			_preload_type(type.name, writer)
		
		for name: String in type.properties.keys():
			var prop_type: GD.Types.GodotType = type.properties[name].type
			_observe_type_for_preload(prop_type, writer)
	
	elif type.id == GD.Types.Id.Array:
		_observe_type_for_preload(type.sub_type_value, writer)
	elif type.id == GD.Types.Id.Dict:
		_observe_type_for_preload(type.sub_type_key, writer)
		_observe_type_for_preload(type.sub_type_value, writer)


static func generate_response_for(schema: Schema, is_api_response: bool, writer: GD.Writer, custom_name: String = '') -> GD.Types.GodotClass:
	#region class decl
	if schema.description != '':
		writer.comment(_format_doc_comment(schema.description, writer), true).eol()
	
	if custom_name != '':
		writer.add_class(custom_name)
	else:
		writer.add_class(schema.type.name)
	
	if schema.type.properties.size() == 0:
		writer.add_field(
			GD.Types.GodotVariable.new("result", schema.type, false, false)
		)
	else:
		#region Properties
		for name: String in schema.type.properties.keys():
			var property: GD.Types.GodotTypeProperty = schema.type.properties[name]
			
			#region Doc comment
			if property.metadata.get("description", '') != '':
				writer.comment(_format_doc_comment(property.metadata["description"], writer), true).eol()
			if !property.required:
				writer.comment("(optional)", true).eol()
			#endregion
			#region Field
			var default_value_expr: String = ''
			if !property.required:
				default_value_expr = GD.Types.get_default_type_expr(property.type.id)
			
			var postfix: String = ''
			if property.type.id == GD.Types.Id.DateTime:
				postfix = "_unix"
			
			writer.add_field(
				GD.Types.GodotVariable.new(
					name + postfix, property.type, false, false, default_value_expr
				)
			)
			#endregion
		#endregion
	#endregion
	
	# self. or result.
	var target_object_name: String = "result"
	if is_api_response:
		target_object_name = "self"
		# Response specific fields
		writer.eol().add_field(GD.Types.GodotVariable.new(
			"error"
		)).add_field(GD.Types.GodotVariable.new(
			"error_message", GD.Types.String_
		))
	writer.eol()
	
	#region .deserialize(data) method
	var data_json_type: GD.Types.GodotType = _get_data_arg_type_for(schema)
	var return_type: GD.Types.GodotType = GD.Types.Void if is_api_response else writer.cur_class.as_type()
	
	writer.add_method(GD.Types.GodotFunction.new(
		"deserialize", 
		[GD.Types.GodotFunctionArg.new("data", data_json_type)], 
		return_type, 
		!is_api_response,
	))
	
	if !is_api_response:
		writer.add_var(GD.Types.GodotVariable.new(
			"result", return_type
		)).eol().eol(true)
	
	if schema.type.properties.size() == 0:
		#region Single result deserialization
		if schema.type.id == GD.Types.Id.Array:
			if schema.type.sub_type_value.id == GD.Types.Id.Class:
				var _item_expr: String = str(
					target_object_name + ".result.push_back(",
					schema.type.sub_type_value.name, ".deserialize(item))"
				)
				writer.for_in(
					"item",
					GD.Types.TypedExpr.new("data", data_json_type),
					data_json_type.sub_type_value
				).eol().codeline(_item_expr, false).end().eol(true)
			else:
				writer.codeline(target_object_name + ".result = data")
		else:
			writer.codeline(target_object_name + ".result = data")
		#endregion
	else:
		#region Properties deserialization
		for name: String in schema.type.properties.keys():
			var property: GD.Types.GodotTypeProperty = schema.type.properties[name]
			var nameCamel: String = name.to_camel_case()
			
			if !property.required:
				writer.if_('data.has("' + nameCamel + '")').eol()
				_deserialize_property_from_data_json(
					target_object_name, name, property, 
					data_json_type, writer
				)
				writer.end()
			else:
				writer.codeline('assert(data.has("' + nameCamel + '"), "Missing parameter \\"' + nameCamel + '\\"")')
				_deserialize_property_from_data_json(
					target_object_name, name, property, 
					data_json_type, writer
				)
			
			writer.eol(true)
		#endregion
	#endregion
	
	var result: GD.Types.GodotClass = writer.cur_class
	if !is_api_response:
		writer.codeline("return result")
	writer.end_method().end_class()
	writer.code = writer.code.strip_edges(false)
	writer.eol()
	
	return result


static func generate_api_group(category: String, version: String, endpoints: Array, writer: GD.Writer) -> void:
	#region Base
	writer.comment(category.capitalize() + ' ' + version).eol().codeline(
		'const ResponseJson = preload("res://addons/hathora_api/core/http.gd").ResponseJson'
	).eol().eol()
	event_bus_script_writer.comment("region " + category, false, false, 0).eol()
	#endregion
	
	preloaded_types.clear()
	for endpoint: ApiEndpoint in endpoints:
		writer.comment("region " + endpoint.name_snake, false, false, 0).eol()
		#region Signal for EventBus
		var signal_name: String = "on_" + endpoint.name_snake + '_' + version
		
		event_bus_script_writer.raw_expr("signal " + signal_name + '(')
		if endpoint.ok_response != null:
			event_bus_script_writer.raw_expr("response")
		event_bus_script_writer.raw_expr(')').eol()
		#endregion
		
		#region Response cls
		var response_cls: GD.Types.GodotClass
		
		if endpoint.ok_response != null:
			response_cls = generate_response_for(
				endpoint.ok_response.schema, true, 
				writer, endpoint.nameDefault + "Response"
			)
			# To avoid preloading "self" response from common_types
			var response_type: GD.Types.GodotType = response_cls.as_type()
			preloaded_types[response_type.name] = response_type
			_observe_type_for_preload(response_type, writer)
		else:
			writer.add_class(
				endpoint.nameDefault
			).add_field(
				GD.Types.GodotVariable.new("error")
			).add_field(GD.Types.GodotVariable.new(
				"error_message", GD.Types.String_
			))
			response_cls = writer.cur_class
			writer.end_class()
		
		writer.eol().eol()
		#endregion
		
		var response_type: GD.Types.GodotType = response_cls.as_type()
		var function_args: Array[GD.Types.GodotFunctionArg] = _generate_func_args_for(endpoint)
		
		#region Async func
			#region decl
		writer.add_function(
			GD.Types.GodotFunction.new(
				endpoint.name_snake + "_async", function_args,
				response_type, true, true
			)
		)
			#endregion
			#region asserts
		for assert_: String in DEFAULT_ASSERTS:
			writer.codeline(assert_)
		
		if endpoint.security.has(ApiEndpoint.Security.Dev):
			for assert_: String in SERVER_ASSERTS:
				writer.codeline(assert_)
		
		for arg: GD.Types.GodotFunctionArg in function_args:
			var name_: String = arg.name.to_lower()
			if name_ == "region":
				writer.codeline('assert(Hathora.REGIONS.has(region), "ASSERT! Region `" + region + "` doesn\'t exists")')
			elif name_ == "visibility" :
				writer.codeline('assert(Hathora.VISIBILITIES.has(visibility), "ASSERT! Visibility `" + visibility + "` doesn\'t exists")')
			#endregion
		
		writer.eol(true)
		writer.add_var(GD.Types.GodotVariable.new(
			"result", response_type, false, false, response_type.name + '.new()'
		)).eol()
		
			#region Url path exprs
		var url_path_exprs: Dictionary = {}
		for name: String in endpoint.path_params.keys():
			var param: GD.Swagger.ApiEndpointUrlParam = endpoint.path_params[name]
			if KNOWN_CONSTANTS.has(param.nameDefault):
				url_path_exprs['"' + param.nameDefault + '"'] = KNOWN_CONSTANTS[param.nameDefault]
			else:
				url_path_exprs['"' + param.nameDefault + '"'] = param.name_snake
			#endregion
		
			#region Url var
		writer.add_var(GD.Types.GodotVariable.new(
			"url", GD.Types.String_, false, false, 
			'"https://api.hathora.dev' + endpoint.url
		))
		if !url_path_exprs.is_empty():
			writer.raw_expr(
				'".format('
			).dict_expr(url_path_exprs, true, false, false).eol().raw_expr(')', true).eol()
		else:
			writer.raw_expr('"').eol()
		writer.eol()
			#endregion
		
			#region Url query
		var url_query_exprs: Dictionary = {}
		for name: String in endpoint.query_params.keys():
			var param: GD.Swagger.ApiEndpointUrlParam = endpoint.query_params[name]
			if KNOWN_CONSTANTS.has(param.nameDefault):
				url_query_exprs['"' + param.nameDefault + '"'] = KNOWN_CONSTANTS[param.nameDefault]
			else:
				url_query_exprs['"' + param.nameDefault + '"'] = param.name_snake
		
		if !url_query_exprs.is_empty():
			writer.codeline(
				"url += Hathora.Http.build_query_params(", false
			).dict_expr(url_query_exprs, true, false, false).eol().codeline(')')
			#endregion
		
			#region Headers exprs
		var headers_exprs: Array[String] = []
		if endpoint.request_body != null:
			headers_exprs.push_back('"Content-Type: application/json"')
		if endpoint.security.has(ApiEndpoint.Security.User):
			headers_exprs.push_back('"Authorization: " + auth_token')
		if endpoint.security.has(ApiEndpoint.Security.Dev):
			headers_exprs.push_back("Hathora.DEV_AUTH_HEADER")
			#endregion
			
			#region Body expr
		var body_exprs: Dictionary = {}
		if endpoint.request_body != null:
			var body_schema: GD.Swagger.Schema = endpoint.request_body.schema
		
			for name: String in body_schema.type.properties.keys():
				body_exprs['"' + name.to_camel_case() + '"'] = name
			#endregion
		
			#region Api response
		writer.comment("Api call").eol()
		writer.add_var(
			GD.Types.GodotVariable.new("api_response", GD.Types.class_("ResponseJson"))
		).raw_expr(
			" = await Hathora.Http." + endpoint.http_method + "_async("
		).eol().raw_expr("\turl,", true).eol().raw_expr('', true).arr_expr(
			headers_exprs, false, true
		)
		if endpoint.http_method == "post":
			writer.raw_expr(",\n").dict_expr(body_exprs, true, true)
		writer.eol().codeline(')')
			#endregion
			
			#region Api errors
		writer.comment("Api errors").eol().codeline(
			"result.error = api_response.error"
		).if_(
			"result.error != Hathora.Error.Ok"
		).eol().comment(
			"WARNING: Human! I need your help - write custom error messages"
		).eol().comment(
			"List of error codes: " + str(endpoint.error_responses.keys())
		).eol().codeline(
			"result.error_message = Hathora.Error.push_default_or("
		).codeline(
			"\tapi_response, {}"
		).codeline(')')
		
		if response_cls.properties.size() > 2:
			writer.else_().eol().codeline("result.deserialize(api_response.data)")
		writer.end().eol(true)
			#endregion
		
		writer.raw_expr(
			"HathoraEventBus." + signal_name + ".emit(", true
		)
		if response_cls.properties.size() > 2:
			writer.raw_expr("result)")
		else:
			writer.raw_expr(')')
		writer.eol().codeline("return result")
		
		#endregion
		writer.end_func().eol().eol()
		
		#region Sync func
		writer.add_function(
			GD.Types.GodotFunction.new(
				endpoint.name_snake, function_args,
				GD.Types.Signal_, true, false
			)
		)
		
			#region Call to async
		var args_exprs: Array[String] = []
		for _arg: GD.Types.GodotFunctionArg in function_args:
			args_exprs.push_back(_arg.name)
		
		writer.call_unsafe(
			endpoint.name_snake + "_async",
			args_exprs, false, true
		).eol()
			#endregion
		writer.codeline("return HathoraEventBus." + signal_name)
		writer.end_func()
		#endregion
		
		writer.comment("endregion", false, false, 0).eol().eol().eol()
	
	event_bus_script_writer.comment("endregion", false, false, 0).eol().eol()
#endregion
