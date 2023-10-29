enum Id {
	Dynamic = TYPE_MAX,
	Void = TYPE_NIL,
	Bool = TYPE_BOOL,
	Int = TYPE_INT,
	Float = TYPE_FLOAT,
	String = TYPE_STRING,
	Array = TYPE_ARRAY,
	PackedByte = TYPE_PACKED_BYTE_ARRAY,
	PackedFloat32 = TYPE_PACKED_FLOAT32_ARRAY,
	PackedFloat64 = TYPE_PACKED_FLOAT64_ARRAY,
	PackedInt32 = TYPE_PACKED_INT32_ARRAY,
	PackedInt64 = TYPE_PACKED_INT64_ARRAY,
	PackedString = TYPE_PACKED_STRING_ARRAY,
	Dict = TYPE_DICTIONARY,
	Class = TYPE_OBJECT,
	Signal = TYPE_SIGNAL,
	DateTime = -1,
}

##region     -- Default types
static var Void: GodotType =  GodotType.create("void", Id.Dynamic)
static var Dynamic: GodotType = GodotType.create('', Id.Dynamic)
static var Bool: GodotType = GodotType.create("bool", Id.Bool)
static var Float: GodotType = GodotType.create("float", Id.Float)
static var Int: GodotType = GodotType.create("int", Id.Int)
static var GodotString: GodotType = GodotType.create("String", Id.String)
static var GodotSignal: GodotType = GodotType.create("Signal", Id.Class)
static var EmtpyDict: GodotType = GodotType.create("Dictionary", Id.Dict, Void, Void)
##endregion  -- Default types

# Note: Those types don't exist in GDScript, but used as a representation
##region     -- Custom types
## Unix time
static var DateTime: GodotType = GodotType.create("int", Id.DateTime)
##endregion  -- Custom types


class GodotType:
	var id: Id
	var name: String
	## Type for *inner* values (exists in Array and Dictionary)
	var value_sub_type: GodotType
	## Type for keys (exists ONLY in Dictionary)
	var key_sub_type: GodotType
	
	static func create(name: String, id: Id, value_type: GodotType = null, key_type: GodotType = null) -> GodotType:
		var result: GodotType = GodotType.new()
		result.id = id
		result.name = name
		result.value_sub_type = value_type
		result.key_sub_type = key_type
		return result
	
	## Returns true if type can be used for statically typed 
	## variables/fields/args/etc.
	static func _is_static(type: GodotType) -> bool:
		return type != null and type != GD.Types.Void and type != GD.Types.Dynamic
	
	## Builds an expression for current type
	## (including [member self.value_sub_type] and [member self.key_sub_type]
	func build() -> String:
		if (GodotType._is_static(self.key_sub_type) 
				and GodotType._is_static(self.value_sub_type)):
			# Feature exists only in 4.2+ version
			if Engine.get_version_info()["minor"] >= 2:
				return str(
					self.name, '[', self.value_sub_type.build(),
					", ", self.key_sub_type.build(), ']'
				)
		
		if GodotType._is_static(self.value_sub_type):
			return self.name + '[' + self.value_sub_type.build() + ']'
		
		return self.name
	
	func get_default_expr() -> String:
		return GD.Types.get_default_type_expr(self.id)


## Creates a unique Array type representation with specified sub type
## (by default [param sub_type] is dynamic).
## Note: [param sub_type] CAN'T have any _sub_type defined because
## at the time of the writting gdscript doesn't support this.
## (Might become obsolete in 4.2)
static func array(sub_type: GodotType = GD.Types.Dynamic) -> GodotType:
#	assert(
#		(sub_type.value_sub_type == null 
#			or sub_type.value_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Array typing!"
#	)
#	assert(
#		(sub_type.key_sub_type == null 
#			or sub_type.key_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Array typing!"
#	)
	
	return GodotType.create("Array", Id.Array, sub_type)


## TODO: doc
static func _packed_array(sub_id: Id) -> GodotType:
	match sub_id:
		Id.PackedByte:
			return class_("PackedByteArray")
		Id.PackedFloat32:
			return class_("PackedFloat32Array")
		Id.PackedFloat64:
			return class_("PackedFloat64Array")
		Id.PackedInt32:
			return class_("PackedInt32Array")
		Id.PackedInt64:
			return class_("PackedInt64Array")
		Id.PackedString:
			return class_("PackedStringArray")
		_:
			push_error("Unknown type id value: `" + str(sub_id) + '`')
			breakpoint
			return null


## TODO: doc
static func packed_array(type_name: String, type_format: String) -> GodotType:
	match type_name:
		"integer":
			match type_format:
				"int32":
					return _packed_array(Id.PackedInt32)
				"int64":
					return _packed_array(Id.PackedInt64)
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"number":
			match type_format:
				"float":
					return _packed_array(Id.PackedFloat32)
				"double":
					return _packed_array(Id.PackedFloat64)
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"string":
			if type_format.contains("date"):
				# Unix time
				return _packed_array(Id.PackedInt64)
			return _packed_array(Id.PackedString)
		_:
			push_error("Godot doesn't have PackedArray for: `", type_name + '`')
			breakpoint
			return null


## Creates a unique Dictionary type representation with specified sub types
## (by default [param sub_type] and [param sub_type] are dynamic).
## Note: [param sub_type] and [param sub_type] CAN'T have any _sub_type defined because
## at the time of the writting gdscript doesn't support this.
static func dict(key_type: GodotType = GD.Types.Dynamic, value_type: GodotType = GD.Types.Dynamic) -> GodotType:
#	assert(
#		(key_type.value_sub_type == null 
#			or key_type.value_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Dictionary typing!"
#	)
#	assert(
#		(key_type.key_sub_type == null 
#			or key_type.key_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Dictionary typing!"
#	)
#	assert(
#		(value_type.value_sub_type == null 
#			or value_type.value_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Dictionary typing!"
#	)
#	assert(
#		(value_type.key_sub_type == null 
#			or value_type.key_sub_type == GD.Types.Void), 
#		"Gdscript doesn't support nestead Dictionary typing!"
#	)
	
	return GodotType.create("Dictionary", Id.Dict, value_type, key_type)


## Creates a type representation for user-defined class
static func class_(name: String) -> GodotType:
	return GodotType.create(name, Id.Class)


## Converts openapi type representation to gd type representation.
## (For more info see: # See: https://spec.openapis.org/oas/v3.0.0.html#dataTypes)
## Note: If [param alias_name] exists than it will return class instead of plain Dictionary
static func swagger_to_gd(type: String, type_format: String, alias_name: String = '') -> GodotType:
	match type:
		"integer":
			match type_format:
				"int32":
					return Int
				"int64":
					return Int
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"number":
			match type_format:
				"float":
					return Float
				"double":
					return Float
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"string":
			match type_format:
				'':
					return GodotString
				"byte":
					return GodotString
				"binary":
					return GodotString
				"date":
					return DateTime
				"date-time":
					return DateTime
				"password":
					return GodotString
				_:
					push_error("Unknown type_format: `" + type_format + "`")
					breakpoint
					return null
		"boolean":
			return Bool
		"Record_string.never_":
			return EmtpyDict
		"object":
			if alias_name == '':
				return dict()
			return class_(alias_name)
		"array":
			return array()
		_:
			push_error("Unknown type: `" + type + "`")
			breakpoint
			return null


static func get_default_type_expr(type_id: Id, bool_default: bool = false) -> String:
	match type_id:
		Id.Dynamic:
			return "null"
		Id.Bool:
			if bool_default:
				return "true"
			return "false"
		Id.Int:
			return '0'
		Id.Float:
			return '0.0'
		Id.String:
			return "''"
		Id.Array:
			return "[]"
		Id.PackedByte:
			return "[]"
		Id.PackedFloat32:
			return "[]"
		Id.PackedFloat64:
			return "[]"
		Id.PackedInt32:
			return "[]"
		Id.PackedInt64:
			return "[]"
		Id.PackedString:
			return "[]"
		Id.Dict:
			return "{}"
		Id.Class:
			return "null"
		Id.Signal:
			return "null"
		Id.Void:
			push_error("Default value expression can't exist for Void type!")
			breakpoint
			return ''
		_:
			push_error("Can't get default value expression for unknown type id: `" + str(type_id) + '`')
			breakpoint
			return "null"
