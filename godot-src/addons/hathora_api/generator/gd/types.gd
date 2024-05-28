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

#region     -- Default types
static var Void: GodotType = GodotType.new("void", Id.Dynamic)
static var Dynamic: GodotType = GodotType.new("Variant", Id.Dynamic)
static var Bool: GodotType = GodotType.new("bool", Id.Bool)
static var Float: GodotType = GodotType.new("float", Id.Float)
static var Int: GodotType = GodotType.new("int", Id.Int)
static var String_: GodotType = GodotType.new("String", Id.String)
static var Signal_: GodotType = GodotType.new("Signal", Id.Signal)
# Note: Dictionary and Array are not on this list because they have subtypes
#endregion  -- Default types


#region     -- Custom types
## Unix time
static var DateTime: GodotType = GodotType.new("int", Id.DateTime)
#endregion  -- Custom types


class GodotType:
	#region Required
	var id: Id
	var name: String
	#endregion
	#region Optional
	## name: String; property: GodotTypeProperty
	## (optional - empty dict by default)
	var properties: Dictionary = {}
	## name: String; function: GodotFunction
	## (optional - empty dict by default)
	var functions: Dictionary = {}
	## Example - Array[T], Dictionary[..., T]
	## (optional - null by default)
	var sub_type_value: GodotType = null
	## Example - Dictionary[T,...]
	## (optional - null by default)
	var sub_type_key: GodotType = null
	#endregion
	
	func _init(name: String, type_id: Id, sub_type_value: GodotType = null, 
			sub_type_key: GodotType = null) -> void:
		self.name = name
		self.id = type_id
		
		self.sub_type_value = sub_type_value
		self.sub_type_key = sub_type_key
	
	func _to_string() -> String:
		var result: String = self.name
		
		## NOTE: At the time of the writting typed dictionaries are not supported :(
		if Engine.get_version_info().minor >= 3 and self.sub_type_key != null:
			result += '[' + str(self.sub_type_key).trim_prefix('[').trim_suffix(']')
			if self.sub_type_value != null:
				result += ", " + str(self.sub_type_key).trim_prefix('[').trim_suffix(']') + ']'
		elif sub_type_key == null and self.sub_type_value != null:
			result += '[' + str(self.sub_type_value).trim_prefix('[').trim_suffix(']') + ']'
		
		return result
	
	func equals(other: GodotType) -> bool:
		return GD.Types.is_equal(self, other)
	
	func add_property(property_name: String, property: GodotTypeProperty, override: bool = false) -> GodotType:
		if self.properties.has(name) and not override:
			return
		
		self.properties[property_name] = property
		return self
	
	func add_function(function: GodotFunction, override: bool = false) -> GodotType:
		if self.functions.has(name) and not override:
			return
		
		self.functions[name] = function
		return self


class GodotTypeProperty:
	var type: GodotType
	var required: bool = true
	## Not used anywhere, left for user to store any additional data
	var metadata: Dictionary = {}
	
	func _init(type: GodotType, required: bool = true, metadata: Dictionary = {}) -> void:
		self.type = type
		self.required = required
		self.metadata = metadata


class TypedExpr:
	var value: String
	var type: GodotType
	
	func _init(value_expression: String, type: GodotType) -> void:
		self.value = value_expression
		self.type = type
	
	func _to_string() -> String:
		return value


#region Godot primitives
## Very similar to GodotType, but contains an actual property data
## instead of type-only info
class GodotClass:
	var name: String
	## property_name: String; property: GodotVariable
	## (optional - empty dict by default)
	var properties: Dictionary = {}
	## function_name: String; function: GodotFunction
	## (optional - empty dict by default)
	var functions: Dictionary = {}
	
	func _init(name: String) -> void:
		self.name = name
	
	func as_type() -> GodotType:
		var result: GodotType = GD.Types.class_(self.name)
		#region Properties
		for name: String in self.properties.keys():
			var field: GodotVariable = self.properties[name]
			result.add_property(
				name, GodotTypeProperty.new(field.type)
			)
		#endregion
		#region Functions
		for function: GodotFunction in self.functions.values():
			result.add_function(function)
		#endregion
		
		return result
	
	func add_property(property: GodotVariable, override: bool = false) -> GodotClass:
		if self.properties.has(property.name) and not override:
			return
		
		self.properties[property.name] = property
		return self
	
	func add_method(function: GodotFunction, override: bool = false) -> GodotClass:
		if self.functions.has(function.name) and not override:
			return
		
		self.functions[function.name] = function
		return self


class GodotFunction:
	var name: String
	var args: Array[GodotFunctionArg]
	## (void by default)
	var return_type: GodotType = GD.Types.Void
	## (false by default)
	var is_static: bool = false
	## (false by default)
	var is_async: bool = false
	
	func _init(name: String, args: Array[GodotFunctionArg] = [], return_type: GodotType = GD.Types.Void, is_static: bool = false, is_async: bool = false) -> void:
		self.name = name
		self.args = args
		self.return_type = return_type
		self.is_static = is_static
		self.is_async = is_async
		# Args order is wrong unless sorted twice O_o
		self._sort_args()
		self._sort_args()
	
	func add_arg(arg: GodotFunctionArg) -> GodotFunction:
		self.args.push_back(arg)
		self._sort_args()
		return self
	
	func _sort_args() -> void:
		self.args.sort_custom(
			func(a: GodotFunctionArg, b: GodotFunctionArg) -> bool:
				return not b.required
		)
	
	func _to_string() -> String:
		var result: String = ''
		
		if self.is_static:
			result += "static "
		result += "func " + self.name + '('
		
		for arg in self.args:
			result += str(arg) + ", "
		result = result.trim_suffix(", ")
		
		result += ") -> " + str(self.return_type) + ':'
		return result


class GodotFunctionArg:
	var name: String
	var type: GodotType = GD.Types.Dynamic
	var required: bool = true
	
	func _init(name: String, type: GodotType = GD.Types.Dynamic, required: bool = true) -> void:
		self.name = name
		self.type = type
		self.required = required
	
	func _to_string() -> String:
		var result: String = self.name + ": " + str(self.type)
		
		if not self.required:
			return result + " = " + GD.Types.get_default_type_expr(self.type.id)
		return result


class GodotVariable:
	var name: String
	var type: GodotType = GD.Types.Dynamic
	## Expression
	var value: String = ''
	
	var is_static: bool = false
	var is_const: bool = false
	
	func _init(name: String, type: GodotType = GD.Types.Dynamic, 
			is_static: bool = false, is_const: bool = false, value_expr: String = '') -> void:
		self.name = name
		self.type = type
		self.value = value_expr
		
		assert(not (is_static and is_const), "In gdscript variables can't be both static and const")
		self.is_static = is_static
		self.is_const = is_const
	
	func set_value(expression: String) -> GodotVariable:
		self.value = expression
		return self
	
	func set_equals(typed_expr: TypedExpr) -> GodotVariable:
		assert(self.type.equals(typed_expr.type), "Type of the variable doesn't match the type of the expression!")
		self.set_value(typed_expr.value)
		return self
	
	func _to_string() -> String:
		var result: String = ''
		
		if self.is_static:
			result += "static var "
		else:
			result += "const " if self.is_const else "var "
		
		result += self.name + ": " + self.type.to_string()
		
		if self.value != '':
			result += " = " + self.value
		
		return result
#endregion


#region Utility functions
static func is_equal(type_a: GodotType, type_b: GodotType) -> bool:
	return (
		type_a.name == type_b.name and type_a.id == type_b.id and 
		is_equal(type_a.sub_type_key, type_b.sub_type_key) and
		is_equal(type_a.sub_type_value, type_b.sub_type_value)
	)


## Creates an Array type with specified sub type
## ([param sub_type] - dynamic by default).
static func array(sub_type: GodotType = GD.Types.Dynamic) -> GodotType:
	return GodotType.new("Array", Id.Array, sub_type)


## Creates a Dictionary type with specified key and value sub types
## ([param sub_type] and [param sub_type] are dynamic by default).
static func dict(key_type: GodotType = GD.Types.Dynamic, value_type: GodotType = GD.Types.Dynamic) -> GodotType:
	return GodotType.new("Dictionary", Id.Dict, value_type, key_type)


## Creates a type representation for a class
static func class_(name: String) -> GodotType:
	return GodotType.new(name, Id.Class)


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
		Id.DateTime:
			return "-1"
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
			return ''
#endregion
