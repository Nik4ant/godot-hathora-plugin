const Types = GD.Types


static var SCHEMAS_TYPE_EXCEPTIONS: Dictionary = {
	"Record_string.never_": Types.dict(Types.Void, Types.Void),
	#"Omit_Room.allocations_": Types.dict(Types.Dynamic, Types.Dynamic)
}

#region Parsing
static func _deep_merge_array(array_1: Array, array_2: Array) -> Array:
	var new_array: Array = array_1.duplicate(true)
	var compare_array: Array = new_array
	var item_exists: Variant
	
	compare_array = []
	for item: Variant in new_array:
		if item is Dictionary or item is Array:
			compare_array.append(JSON.stringify(item))
		else:
			compare_array.append(item)

	for item: Variant in array_2:
		item_exists = item
		if item is Dictionary or item is Array:
			item = item.duplicate(true)
			item_exists = JSON.stringify(item)
		
		if not item_exists in compare_array:
			new_array.append(item)
	return new_array

# (test on ApplicationWithDeployment to see if deployment property appears)
static func _deep_merge(dict_1: Dictionary, dict_2: Dictionary) -> Dictionary:
	var result: Dictionary = dict_1.duplicate(true)
	for key: Variant in dict_2.keys():
		if key in result:
			if dict_1[key] is Dictionary and dict_2[key] is Dictionary:
				result[key] = _deep_merge(dict_1[key], dict_2[key])
			elif dict_1[key] is Array and dict_2[key] is Array:
				result[key] = _deep_merge_array(dict_1[key], dict_2[key])
			else:
				result[key] = dict_2[key]
		else:
			result[key] = dict_2[key]
	return result


static func _get_ref_name(data_with_ref: Dictionary) -> String:
	return data_with_ref["$ref"].split('/')[-1]


## Recursevly loads schema either by specified [param type_name] or
## by $ref defined in [param _previous].
## Result - flattened down type schema with extra field(s) inside:
## __name__ - class_name for types (used to prevent name
## from being lost while loading $ref path)
## __is_complex__ = true if __name__ reperesents class_name for an "object"
## with properties and not a type alias or Dictionary
static func _get_type_schema(type_name: String, schemas_source: Dictionary, _previous: Dictionary = {}) -> Dictionary:
	assert(not type_name.begins_with("#/"), "You MUST pass a NAME at the end of the $ref and not the $ref itself")
	
	var raw_schema: Dictionary
	if _previous.is_empty():
		assert(schemas_source.has(type_name), "ERROR! Schema with the name `" + type_name + "` doesn't exist")
		raw_schema = schemas_source[type_name]
	else:
		raw_schema = _previous
	
	var full_schema: Dictionary
	if type_name != '':
		full_schema["__name__"] = type_name
	
	# Proper solution - detect differences between schemas and
	# merge them together into one with optional fields, but
	# this would require too much effort for a single edge case
	if raw_schema.has("anyOf"):
		raw_schema = _get_type_schema(
			'', schemas_source, raw_schema["anyOf"][0]
		)
	
	# If result IS a combination of multiple schemas
	if raw_schema.has("allOf"):
		var combination: Dictionary = {}
		for item in raw_schema["allOf"]:
			var merge_target: Dictionary
			# If item IS a $ref
			if item.has("$ref"):
				var name: String = _get_ref_name(item)
				var current: Dictionary = _get_type_schema(name, schemas_source)
				current["__name__"] = name
				merge_target = current.duplicate(true)
			# Else item IS a flattened schema
			else:
				merge_target = _get_type_schema('', schemas_source, item)
			
			if combination.is_empty():
				combination = merge_target.duplicate(true)
			else:
				combination = _deep_merge(combination, merge_target)
			
		if type_name != '':
			combination["__name__"] = type_name
		raw_schema = combination
		return raw_schema
	# If result HAS items, load info about those items
	elif raw_schema.has("items"):
		raw_schema["items"] = _get_type_schema('', schemas_source, raw_schema["items"])
	# If result IS a $ref - load it first
	elif raw_schema.has("$ref"):
		var name: String = _get_ref_name(raw_schema)
		raw_schema = _get_type_schema(name, schemas_source)
		raw_schema["__name__"] = name
	
	# If result IS a flattened type - just return it
	if not raw_schema.has("properties"):
		raw_schema["__is_complex__"] = false
		return raw_schema
	
	full_schema.merge(raw_schema)
	var any_properties: bool = false
	# If result is NOT a flattened type - load properties recursivly
	var properties = full_schema["properties"]
	for property_name in properties.keys():
		# Note: This is check is 99% redundent, but exist 
		# only just in case...
		if property_name.begins_with("__"):
			full_schema[property_name] = raw_schema[property_name]
			continue
		any_properties = true
		var value: Dictionary = properties[property_name]
		if value.is_empty():
			full_schema["properties"][property_name] = {
				"type": "object"
			}
		else:
			full_schema["properties"][property_name] = _get_type_schema('', schemas_source, value)
	
	if any_properties and full_schema.get("type", "object") == "object":
		full_schema["__is_complex__"] = true
	else:
		full_schema["__is_complex__"] = false
	
	# NOTE: Certain schemas are <i>interesting</i>.
	# For example, "Record_string.never_" has an empty "properties"
	# resulting into an {}. 
	# To make sure all corner cases are handled, type information 
	# about those <i>interesting</i> exceptions is added
	if full_schema.is_empty():
		const EXCEPTIONS: Array[String] = [
			"Record_string.never_"
		]
		assert(EXCEPTIONS.has(type_name), "ASSERT! New empty exception was found")
		full_schema = {
			"type": type_name
		}
	
	return full_schema


## Gets the content of `application/json` schema or `plain/text` schema
## (Returns null if schema wasn't found)
static func _get_content_schema(raw_json: Dictionary, all_schemas: Dictionary) -> Variant:
	var schema_json = GD.Utils.safe_get(
		raw_json, "content-application/json-schema", null, '-'
	)
	
	if schema_json == null:
		schema_json = raw_json.get("schema", null)
		if schema_json == null:
			schema_json = GD.Utils.safe_get(
				raw_json, "content-text/plain-schema", null, '-'
			)
	
	return schema_json
#endregion

#region GD convertion
## Converts openapi + exclusive schema types to closest existing Godot type
## (See: https://spec.openapis.org/oas/v3.0.0.html#dataTypes)
## Returns class instead of plain Dictionary if [param alias_name] exists
static func swagger_type_to_gd(type: String, type_format: String, alias_name: String = '') -> Types.GodotType:
	match type:
		"integer":
			match type_format:
				"int32":
					return Types.Int
				"int64":
					return Types.Int
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"number":
			match type_format:
				"float":
					return Types.Float
				"double":
					return Types.Float
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"string":
			match type_format:
				'':
					return Types.String_
				"byte":
					return Types.String_
				"binary":
					return Types.String_
				"date":
					return Types.DateTime
				"date-time":
					return Types.DateTime
				"password":
					return Types.String_
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"boolean":
			return Types.Bool
		"object":
			if alias_name == '':
				return Types.dict()
			return Types.class_(alias_name)
		"array":
			return Types.array()
		_:
			assert(SCHEMAS_TYPE_EXCEPTIONS.has(type), "Unknown type: `" + type + "`")
			return SCHEMAS_TYPE_EXCEPTIONS[type]


static func swagger_object_properties_to_gd(target: Types.GodotType, json_properties: Dictionary, required: Array) -> void:
	for name: String in json_properties.keys():
		var json_property: Dictionary = json_properties[name]
		var metadata: Dictionary = {
			"required": json_property.get("required", []),
			"pattern": json_property.get("pattern", ''),
			"example": json_property.get("example", ''),
			"enum": json_property.get("enum", []),
			"description": json_property.get("description", ''),
			"deprecated": json_property.get("deprecated", false),
		}
		
		var property_type: Types.GodotType
		
		#region Property type parsing
		if json_property.has("properties") and json_property.get("__name__", '') != '':
			var _name: String = json_property["__name__"]
			if SCHEMAS_TYPE_EXCEPTIONS.has(_name):
				property_type = SCHEMAS_TYPE_EXCEPTIONS[_name]
			else:
				property_type = Types.class_(json_property["__name__"])
			
			swagger_object_properties_to_gd(
				property_type, json_property["properties"], 
				json_property.get("required", [])
			)
		elif json_property.has("items"):
			var json_items: Dictionary = json_property["items"]
			var property_sub_type: Types.GodotType
			#region Sub type
			if json_items.has("properties") and json_items.get("__name__", '') != '':
				var _name: String = json_items["__name__"]
				if SCHEMAS_TYPE_EXCEPTIONS.has(_name):
					property_sub_type = SCHEMAS_TYPE_EXCEPTIONS[_name]
				else:
					property_sub_type = Types.class_(json_items["__name__"])
				
				swagger_object_properties_to_gd(
					property_sub_type, json_items["properties"], 
					json_items.get("required", [])
				)
			else:
				assert(!json_items.has("items"), "Unknown structure! To-Do: add support for nested structure")
				property_sub_type = swagger_type_to_gd(
					json_items.get("type", "object"), 
					json_items.get("format", ''),
					json_items.get("__name__", '') if json_items.get("__is_complex__", false) else ''
				)
			#endregion
			property_type = Types.array(property_sub_type)
		else:
			property_type = swagger_type_to_gd(
				json_property.get("type", "object"), 
				json_property.get("format", ''),
				json_property.get("__name__", '') if json_property.get("__is_complex__", false) else ''
			)
		#endregion
		
		target.add_property(
			name.to_snake_case(),
			Types.GodotTypeProperty.new(property_type, required.has(name), metadata)
		)


## - TODO: explain [param _items_json]
static func swagger_schema_to_gd(schema_name: String, all_schemas: Dictionary, _items_json: Dictionary = {}) -> Schema:
	var result: Schema = Schema.new()
	
	var schema_json: Dictionary
	if !_items_json.is_empty():
		schema_json = _items_json
	else:
		schema_json = _get_type_schema(schema_name, all_schemas)
	
	#region Type
	if schema_json.get("__is_complex__", false) and schema_json.get("__name__", '') != '':
		var _name: String = schema_json["__name__"]
		if SCHEMAS_TYPE_EXCEPTIONS.has(_name):
			result.type = SCHEMAS_TYPE_EXCEPTIONS[_name]
		else:
			result.type = Types.class_(schema_json["__name__"])
	else:
		result.type = swagger_type_to_gd(
			schema_json.get("type", "object"), 
			schema_json.get("format", ''), 
			schema_name
		)
	#endregion
	#region Items
	if schema_json.has("items"):
		var items_json: Dictionary = schema_json["items"]
		assert(schema_json.get("type", '') == "array", "Unknown structure! `items` is supposed to be an array")
		
		var items_type_name: String = items_json.get("__name__", '')
		if items_json.has("$ref"):
			items_type_name = _get_ref_name(items_json)
		
		result.items = swagger_schema_to_gd(
			items_type_name, all_schemas, items_json
		)
		result.type = Types.array(result.items.type)
	#endregion
	
	#region Schema metadata
	result.required = schema_json.get("required", [])
	result.nullable = schema_json.get("nullable", false)
	result.deprecated = schema_json.get("deprecated", false)
	result.description = schema_json.get("description", '')
	#endregion
	
	#region Properties
	var json_properties: Dictionary = schema_json.get("properties", {})
	if !json_properties.is_empty():
		swagger_object_properties_to_gd(
			result.type,
			json_properties,
			result.required
		)
	#endregion
	
	#region additionalProperties
	if schema_json.get("additionalProperties", null) == false:
		result.type = Types.dict()
	#endregion
	
	return result
#endregion


class Schema:
	var type: Types.GodotType
	var items: Schema
	
	var required: Array = []
	var nullable: bool = false
	var deprecated: bool = false
	var description: String = ''


class ApiEndpoint:
	enum Security {
		Dev,
		User
	}
	
	var nameDefault: String
	var name_snake: String
	var http_method: String
	## v[number]
	var version: String
	## url (path) without a "http(s)://" prefix
	var url: String
	## name: String; path_param: ApiEndpointUrlParam
	var path_params: Dictionary
	## name: String; query_param: ApiEndpointUrlParam
	var query_params: Dictionary
	
	var request_body: ApiEndpointRequestBody
	var ok_response: ApiEndpointResponse
	## http_code: int; response: ApiEndpointResponse
	var error_responses: Dictionary
	
	var security: Array[Security] = []
	var deprecated: bool = false
	var description: String = ''
	var tags: Array = []
	var group_name: String = ''
	
	
	static func from_json(url: String, json: Dictionary, all_schemas: Dictionary) -> ApiEndpoint:
		assert(json.size() == 1, "Unknown schema type with more than 1 http method: " + str(json.keys()))
		var result: ApiEndpoint = ApiEndpoint.new()
		var endpoint_json: Dictionary = json.values()[0]
		
		#region Security
		for item: Dictionary in json.get("security", []):
			if item.has("playerAuth"):
				result.security.push_back(Security.User)
			elif item.has("hathoraDevToken"):
				result.security.push_back(Security.Dev)
			else:
				push_error("Unknown security value `" + str(item) + '`')
				breakpoint
		#endregion
		
		#region Url params
		for param_json: Dictionary in json.get("parameters", []):
			var current: ApiEndpointUrlParam = ApiEndpointUrlParam.from_json(
				param_json, all_schemas
			)
			if current.location == ApiEndpointUrlParam.Location.Path:
				result.path_params[current.nameDefault] = current
			else:
				result.query_params[current.nameDefault] = current
		#endregion
		
		if endpoint_json.has("requestBody"):
			result.request_body = ApiEndpointRequestBody.from_json(endpoint_json["requestBody"], all_schemas)
		
		#region Responses
		var responses_json: Dictionary = endpoint_json.get("responses", {})
		for status_code: String in responses_json.keys():
			var code: int = int(status_code)
			
			if status_code.begins_with('2'):
				assert(result.ok_response == null, "Unknown structure! Endpoint can't have more than 1 successful response")
				result.ok_response = ApiEndpointResponse.from_json(
					code, responses_json[status_code], all_schemas
				)
			else:
				assert(!result.error_responses.has(code), "Unknown structure! Endpoint can't have multiple schemas for the same status code")
				result.error_responses[code] = ApiEndpointResponse.from_json(
					code, responses_json[status_code], all_schemas
				)
		#endregion
		
		#region Other
		result.http_method = json.keys()[0]
		result.url = url
		result.version = _get_version_from_url(url)
		result.nameDefault = endpoint_json["operationId"]
		result.name_snake = result.nameDefault.to_snake_case()
		result.description = endpoint_json.get("description", '')
		result.deprecated = endpoint_json.get("deprecated", false)
		result.tags = endpoint_json.get("tags", [])
		assert(result.tags.size() == 1, "Unknown structure! Endpoint can't have more than 1 tag `" + str(result.tags) + '`')
		result.group_name = (result.tags[0] as String).to_lower().trim_suffix(result.version)
		#endregion
		
		return result
	
	static func _get_version_from_url(url: String) -> String:
		for ver_num in range(10):
			var version: String = str('v', ver_num)
			if url.contains(version):
				return version
		
		push_error("Can't detect version in the given url: `" + url + '`')
		breakpoint
		return ''


static func _schema_from_content_body(raw_json: Dictionary, all_schemas: Dictionary) -> Schema:
	# NOTE :(
	# If you're checking for a $ref twice clap your hand
	# clap-clap
	
	var schema_raw_json = GD.Swagger._get_content_schema(
		raw_json, all_schemas
	)
	
	if schema_raw_json == null:
		if raw_json.has("$ref"):
			var _name: String = GD.Swagger._get_ref_name(raw_json)
			return GD.Swagger.swagger_schema_to_gd(
				_name, all_schemas,
				GD.Swagger._get_type_schema(_name, all_schemas, raw_json)
			)
		
		return GD.Swagger.swagger_schema_to_gd(
			'', all_schemas,
			GD.Swagger._get_type_schema('', all_schemas, raw_json)
		)
	
	if schema_raw_json.has("$ref"):
		return GD.Swagger.swagger_schema_to_gd(
			GD.Swagger._get_ref_name(schema_raw_json), all_schemas
		)
	
	return GD.Swagger.swagger_schema_to_gd(
		'', all_schemas, schema_raw_json
	)


class ApiEndpointUrlParam:
	enum Location {
		Path,
		Query
	}
	
	var nameDefault: String
	var name_snake: String
	var schema: Schema
	var required: bool
	var location: Location
	
	static func from_json(json: Dictionary, all_schemas: Dictionary) -> ApiEndpointUrlParam:
		var result: ApiEndpointUrlParam = ApiEndpointUrlParam.new()
		
		assert(json.has("name"), "Url parameter MUST have a name")
		result.nameDefault = json["name"]
		result.name_snake = result.nameDefault.to_snake_case()
		
		result.required = json.get("required", true)
		
		assert(json.has("in"), "Parameter MUST have a specified \"location\"")
		assert(["query", "path"].has(json["in"]), "Unknown url location for param `" + json["name"] + '`')
		if json["in"] == "path":
			result.location = Location.Path
		else:
			result.location = Location.Query
		
		result.schema = GD.Swagger.swagger_schema_to_gd(
			'', all_schemas, json["schema"]
		)
		
		return result


class ApiEndpointRequestBody:
	var required: bool
	## (if null - empty body)
	var schema: Schema
	
	static func from_json(raw_json: Dictionary, all_schemas: Dictionary) -> ApiEndpointRequestBody:
		var result: ApiEndpointRequestBody = ApiEndpointRequestBody.new()
		result.required = raw_json.get("required", true)
		result.schema = GD.Swagger._schema_from_content_body(
			raw_json, 
			all_schemas
		)
		
		return result


class ApiEndpointResponse:
	var http_code: int
	## (if null - empty response)
	var schema: Schema
	
	static func from_json(http_code: int, raw_json: Dictionary, all_schemas: Dictionary) -> ApiEndpointResponse:
		var result: ApiEndpointResponse = ApiEndpointResponse.new()
		result.http_code = http_code
		result.schema = GD.Swagger._schema_from_content_body(
			raw_json, 
			all_schemas
		)
		
		return result
