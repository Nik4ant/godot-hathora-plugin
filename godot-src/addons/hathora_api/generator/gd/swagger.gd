const Types = GD.Types


static func _get_ref_name(data_with_ref: Dictionary) -> String:
	return data_with_ref["$ref"].split('/')[-1]

## Recursevly loads schema either by specified [param type_name] or
## by $ref defined in [param _previous].
## Result - flattened down type schema with extra field(s) inside:
## __name__ - class_name for types (used to prevent name
## from being lost while loading $ref path)
## __is_complex__ - true if __name__ reperesents class_name for an "object"
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
			# If item IS a $ref
			if item.has("$ref"):
				var name: String = _get_ref_name(item)
				var current: Dictionary = _get_type_schema(name, schemas_source)
				current["__name__"] = name
				combination.merge(current)
			# Else item IS a flattened schema
			else:
				combination.merge(_get_type_schema('', schemas_source, item))
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


class FlatProperty:
	var name_default: String
	var name_snake_case: String
	
	var type_name: String
	var gd_type: Types.GodotType
	var type_format: String = ''
	var type_class_name: String = ''
	
	var items: Schema
	var miniumum: int = 0
	var maxmimum: int = 0
	var max_length: int = 0
	var min_length: int = 0
	var max_items: int = 0
	var min_items: int = 0
	var nullable: bool = false
	var deprecated: bool = false
	var enum_variants: Array = []
	var required: Array = []
	## A regular expression used for validation
	var pattern: String = ''
	var description: String = ''
	## Contains an example value for given property (type - Variant)
	var example
	
	static func parse(name: String, data: Dictionary, schemas_source: Dictionary) -> FlatProperty:
		var result: FlatProperty = FlatProperty.new()
		result.name_default = name
		result.name_snake_case = name.to_snake_case()
		
		assert(data.has("type"), "Flat property MUST have it's type defined")
		result.type_name = data["type"]
		if data.get("__is_complex__", false):
			result.type_class_name = data["__name__"]
		else:
			result.type_class_name = ''
		result.type_format = data.get("format", '')
		
		if data.has("items"):
			var items: Dictionary = data["items"]
			result.items = GD.Swagger.parse_schema(
				items.get("__name__", ''), schemas_source, items
			)
			result.gd_type = Types.array(result.items.gd_type)
		else:
			result.gd_type = Types.swagger_to_gd(
				result.type_name, result.type_format, result.type_class_name
			)
		
		result.miniumum = data.get("miniumum", 0)
		result.maxmimum = data.get("maxmimum", 0)
		result.max_length = data.get("maxLength", 0)
		result.min_length = data.get("minLength", 0)
		result.max_items = data.get("maxItems", 0)
		result.min_items = data.get("minItems", 0)
		result.nullable = data.get("nullable", false)
		result.enum_variants = data.get("enum", [])
		result.required = data.get("required", [])
		result.pattern = data.get("pattern", '')
		result.description = data.get("description", '')
		result.example = data.get("example", null)
		
		return result


static func is_property_flat(data: Dictionary) -> bool:
	var additional_properties = data.get("additionalProperties", null)
	# The only exception are "object" types that have no "properties"
	if additional_properties != null and not additional_properties is Dictionary:
		return true
	
	return (data.get("type", "object") != "object" 
				and not data.get("__is_complex__", false))


class Property:
	var name_default: String
	var name_snake_case: String
	
	var gd_type: Types.GodotType
	var type_name: String = "object"
	var type_class_name: String = ''
	
	## Contains a tree structure, where
	## key - name_default: String; value - property: Property | FlatProperty
	var properties: Dictionary = {}
	## When set to false (bool) - schema isn't allow to have
	## any additional properties (otherwise true).
	## When value is a Dictionary it defines a schema for
	## all properties that are not explicitly defined
	var additional_properties = null
	var required: Array = []
	var nullable: bool = false
	## Is property deprecated
	var deprecated: bool = false
	var description: String = ''
	
	static func parse(name: String, data: Dictionary, schemas_source: Dictionary) -> Property:
		var result: Property = Property.new()
		
		result.name_default = name
		result.name_snake_case = name.to_snake_case()
		
		result.type_name = data.get("type", "object")
		if data.get("__is_complex__", false):
			result.type_class_name = data["__name__"]
		else:
			result.type_class_name = ''
		
		result.gd_type = Types.swagger_to_gd(
			result.type_name, '', result.type_class_name
		)
		
		result.additional_properties = data.get("additionalProperties", null)
		result.required = data.get("required", [])
		result.nullable = data.get("nullable", false)
		result.deprecated = data.get("deprecated", false)
		result.description = data.get("description", '')
		
		return result


class Schema:
	## Contains a tree structure, where
	## key - name_default: String; value - property: Property | FlatProperty
	var properties: Dictionary
	
	var gd_type: Types.GodotType
	var type_name: String
	var items: Schema
	
	## If true [member flat] contains all info about the schema
	## (other fields except [member gd_type] and [member type_name] are ignored)
	var is_flat: bool = false
	var flat: FlatProperty = null
	
	var required: Array = []
	var nullable: bool = false
	var deprecated: bool = false
	var description: String = ''


static func parse_schema(schema_name: String, schemas_source: Dictionary, custom_data: Dictionary = {}) -> Schema:
	var result: Schema = Schema.new()
	var raw_data: Dictionary = _get_type_schema(schema_name, schemas_source, custom_data)
	var _swagger_type_name: String = raw_data.get("type", "object")
	result.type_name = schema_name
	
	if _swagger_type_name == "array" and raw_data.has("items"):
		var items: Dictionary = raw_data["items"]
		result.items = parse_schema(
			items.get("__name__", ''), schemas_source, items
		)
		result.gd_type = Types.array(result.items.gd_type)
	else:
		result.gd_type = Types.swagger_to_gd(
			_swagger_type_name, raw_data.get("format", ''), schema_name
		)
	
	if is_property_flat(raw_data):
		result.is_flat = true
		result.flat = FlatProperty.parse('', raw_data, schemas_source)
		return result
	
	# Parse other info
	result.required = raw_data.get("required", [])
	result.nullable = raw_data.get("nullable", false)
	result.deprecated = raw_data.get("deprecated", false)
	result.description = raw_data.get("description", '')
	
	# Parse properties
	for prop_name in raw_data["properties"].keys():
		var value: Dictionary = raw_data["properties"][prop_name]
		
		if is_property_flat(value):
			result.properties[prop_name] = FlatProperty.parse(
				prop_name, value, schemas_source
			)
		else:
			result.properties[prop_name] = Property.parse(
				prop_name, value, schemas_source
			)
	
	return result


enum Security {
	Dev,
	Auth
}

enum Location {
	Path,
	Query
}

class EndpointParameter:
	var location: Location
	var name_default: String
	var name_snake_case: String
	var required: bool = true
	var schema: Schema
	
	static func parse(data: Dictionary, schemas_source: Dictionary) -> EndpointParameter:
		var result: EndpointParameter = EndpointParameter.new()
		
		assert(data.has("name"), "Parameter MUST have a name")
		result.name_default = data["name"]
		result.name_snake_case = result.name_default.to_snake_case()
		
		result.required = data.get("required", true)
		
		assert(data.has("in"), "Parameter MUST have a specified \"location\"")
		var _location: String = data["in"]
		if _location == "path":
			result.location = Location.Path
		elif _location == "query":
			result.location = Location.Query
		else:
			push_error("Unknown param location value: `" + _location + '`')
			breakpoint
		
		result.schema = GD.Swagger.parse_schema(
			'', schemas_source, data["schema"]
		)
		
		return result


class EndpointResponse:
	var http_code: int
	var schema: Schema
	
	var description: String = ''
	
	static func parse(status_code: int, data: Dictionary, schemas_source: Dictionary) -> EndpointResponse:
		var result: EndpointResponse = EndpointResponse.new()
		result.http_code = status_code
		result.description = data.get("description", '')
		# This is an empty response schema
		if not (data.has("content") or data.has("schema")):
			return result
		
		var schema_info = GD.Utils.safe_get(
			data, "content-application/json-schema", null, '-'
		)
		if schema_info == null:
			schema_info = data.get("schema", null)
			if schema_info == null:
				schema_info = GD.Utils.safe_get(
			data, "content-text/plain-schema", null, '-'
		)
		
		assert(schema_info != null, "Only `application/json` and `text is supported")
		result.schema = GD.Swagger.parse_schema(
			'', schemas_source, schema_info
		)
		
		return result


class EndpointRequestBody:
	var required: bool = true
	var schema: Schema
	
	var description: String = ''
	
	static func parse(data: Dictionary, schemas_source: Dictionary) -> EndpointRequestBody:
		var result: EndpointRequestBody = EndpointRequestBody.new()
		result.required = data.get("required", true)
		result.description = data.get("description", '')
		
		var schema_info: Dictionary = GD.Utils.safe_get(
			data, "content-application/json-schema", null, '-'
		)
		assert(schema_info != null, "Only `application/json` and `text/plain` is supported")
		result.schema = GD.Swagger.parse_schema(
			'', schemas_source, schema_info
		)
		
		return result


class Endpoint:
	var name_PascalCase: String
	var name_snake_case: String
	var path: String
	var version: String
	var http_method: String
	
	var ok_response: EndpointResponse = null
	## key - status_code: int; value - response: EndpointResponse
	var error_responses: Dictionary = {}
	var body: EndpointRequestBody = null
	var params: Array[EndpointParameter] = []
	
	var security: Array[Security] = []
	var deprecated: bool = false
	var description: String = ''
	var tags: Array = []
	
	static func _get_version_from_path(path: String) -> String:
		for ver_num in range(10):
			var version: String = str('v', ver_num)
			if path.contains(version):
				return version
		
		push_error("Can't detect version in given path: `" + path + '`')
		breakpoint
		return ''
	
	static func parse(path: String, _data: Dictionary, schemas_source: Dictionary) -> Endpoint:
		var result: Endpoint = Endpoint.new()
		
		result.path = path
		result.version = _get_version_from_path(path)
		assert(_data.size() == 1, "Expected data with only 1 key (http method), but got: " + str(_data.keys()))
		result.http_method = _data.keys()[0]
		
		var info: Dictionary = _data[result.http_method]
		result.name_PascalCase = info["operationId"]
		result.name_snake_case = result.name_PascalCase.to_snake_case()
		result.description = info.get("description", '')
		result.deprecated = info.get("deprecated", false)
		result.tags = info.get("tags", [])
		
		for item in info.get("security", []):
			if item.has("playerAuth"):
				result.security.push_back(Security.Auth)
			elif item.has("hathoraDevToken"):
				result.security.push_back(Security.Dev)
			else:
				push_error("Unknown security value: `" + item + '`')
				breakpoint
		
		for param in info.get("parameters", []):
			result.params.push_back(
				EndpointParameter.parse(param, schemas_source)
			)
		
		if info.has("requestBody"):
			result.body = EndpointRequestBody.parse(
				info["requestBody"], schemas_source
			)
		
		for status_code in info.get("responses", {}).keys():
			if status_code.begins_with('2'):
				assert(result.ok_response == null, "Endpoint can't have 2 successful responses")
				result.ok_response = EndpointResponse.parse(
					int(status_code), info["responses"][status_code], schemas_source
				)
			else:
				var code: int = int(status_code)
				result.error_responses[code] = EndpointResponse.parse(
					code, info["responses"][status_code], schemas_source
				)
		
		return result
