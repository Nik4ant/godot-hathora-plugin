extends Node


class OpenApiSchema:
	var types: Array[TypeSchema]
	var paths: Array[ApiEndpoint]


class ApiEndpoint:
	var url: String							# (required)
	## v1, v2, v3...
	var version: String						# (required)
	var name_snake_case: String				# (required)
	var name_PascalCase: String				# (required)
	var auth: AuthType						# (required)
	## List of params inside url like {appId} or {roomId} and etc.
	var path_params: Array[UrlParam]		# (optional)
	var query_params: Array[UrlParam]		# (optional)
	## get, post, update, delete
	var http_method: String					# (required)
	## TypeSchema for a request body
	var request_body_schema: Dictionary 	# (optional)
	## List of all possible status codes
	var status_codes: Array[int]			# (optional)
	## All possible response schemas
	## key: status_code (int); value: schema (Dictionary)
	var response_schemas: Dictionary		# (required)


enum AuthType {
	Dev,
	User,
	None
}


## TODO: doc properly
## TL;DR: ref_name - name for schema (end of the path)
## schemas_source - dictionary with loaded components/schemas
static func _get_ref_type(ref_name: String, schemas_source: Dictionary) -> Dictionary:
	var raw_schema: Dictionary = schemas_source.get(ref_name, {})
	if raw_schema.is_empty():
		push_error("Specified schema `" + ref_name + "` doesn't exist!")
		breakpoint
		return {}
	
	var full_schema: Dictionary = raw_schema.get("properties", {})
	for property in full_schema.keys():
		# If property isn't a regular type load type info recursivly
		if full_schema[property].has("$ref"):
			var single_name: String = full_schema[property]["$ref"].split('/')[-1]
			# Note: Record_string.never_ is the only exception here
			# that results into an {} if not handled properly
			# TODO: better explanation?
			if single_name == "Record_string.never_":
				full_schema[property] = {
					"type": "Record_string.never_"
				}
			else:
				full_schema[property] = _get_ref_type(
					single_name, schemas_source
				)
	
	return full_schema


class UrlParam:
	var name: String
	var schema: TypeSchema
	var required: bool
	
	static func deserialize(data: Dictionary, raw_types_info: Dictionary) -> UrlParam:
		var result: UrlParam = UrlParam.new()
		assert(data.has("name"), "Missing field \"name\" in one of the parameter (unexpected)")
		assert(data.has("schema"), "Missing field \"schema\" in one of the parameter (unexpected)")
		assert(data.has("required"), "Missing field \"required\" in one of the parameter (unexpected)")
		result.name = data["name"]
		result.required = bool(data["required"])
		
		if data["schema"].has("$ref"):
			result.schema = TypeSchema.parse(data["schema"]["$ref"], raw_types_info)
		
		return result


class TypeSchema:
	var name: String
	
	## NOTE: If schema ONLY represents another type
	## without having extra properties than this flag is true
	## and info about type is stored inside self.properties[0]
	## (For example, NumRoomsPerProcess is just an integer)
	var is_contained: bool = false
	var properties: Array[Property] = []
	var description: String = ''
	
	## Returns an info about schema with specified [param name].
	## Returns null if schema doesn't exists.
	static func parse(name: String, schemas_source: Dictionary) -> TypeSchema:
		var result: TypeSchema = TypeSchema.new()
		var raw_schema: Dictionary = GDSwagger._get_ref_type(name, schemas_source)
		
		result.name = name
		# Only 2 type schemas have unique structure:
		# 1) Flatten/Contained types (usually an alias for a regular types)
		var type_name: String = raw_schema.get("type", "object")
		if type_name != "object":
			result.is_contained = true
			result.properties = [
				Property.deserialize(name.to_snake_case(), raw_schema)
			]
		# 2) 
		else:
			for raw_property_name in raw_schema.get("properties", {}).keys():
				result.properties.push_back(
					Property.deserialize(
						raw_property_name.to_snake_case(),
						raw_schema["properties"][raw_property_name]
					)
				)
		
		return result


class Property:
	var name_snake_case: String
	var type_name: String
	
	#region     -- Optional
	## Exists ONLY if 
	var items: Array[Property] = []
	## Tells format of current value. 
	## For example, integer - int32, string - date-time and etc.
	var format: String = ''
	## If value is an enum containts all possible values
	var enum_variants: Array[String] = []
	## Contains a regex pattern if only specific chars, digits, etc. can be used
	var pattern: String = ''
	var description: String = ''
	var example: String = ''
	#endregion  -- Optional
	
	static func deserialize(name: String, data: Dictionary) -> Property:
		var result: Property = Property.new()
		result.name_snake_case = name
		
		# 
		if data.has("$ref"):
			pass
		assert(data.has("type"), "ASSERT! Type is missing for property named `" + name + '`')
		result.type_name = data["type"]
		
		result.description = data.get("description", '')
		result.pattern = data.get("pattern", '')
		result.format = data.get("format", '')
		result.example = data.get("example", '')
		result.enum_variants = data.get("enum", [] as Array[String])
		
		if data.has("items"):
			print("WI-WO; WI-WOOO")
			breakpoint
		
		return result
	
	func map_to_gd() -> GD.GodotType:
		match self.type_name:
			"boolean":
				return GD.Types.GodotBool
			"integer":
				return GD.Types.GodotInt
			"number":
				return GD.Types.GodotFloat
			"string":
				return GD.Types.GodotString
			"array":
				assert(len(self.items) != 0, "ASSERT! Found an array without schema for its items")
				# Note: This in theory should recursivly load 
				# all type information
				return GD.GodotType.create(
					"Array", GD.Types.TypeId.Array, self.items[0].map_to_gd()
				)
			# Note: Record_string.never_ is meant to be an emtpy {} object
			"object", "Record_string.never_":
				return GD.Types.GodotDictionary
			_:
				push_error("Can't map schema's type: `" + self.type_name + "` to Godot primitives")
				breakpoint
				return null
