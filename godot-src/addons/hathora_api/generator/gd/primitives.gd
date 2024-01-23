const Type = GD.Types
const GodotType = Type.GodotType
const CodeWriter = GD.Writer.CodeWriter

class Variable:
	var name: String
	var type: GodotType = Type.Dynamic
	
	var value_expr: String = ''
	var is_static: bool = false
	var is_const: bool = false
	
	static func create(name: String, type: GodotType = Type.Dynamic, value_expr: String = '',
			is_static: bool = false, is_const: bool = false) -> Variable:
		var result: Variable = Variable.new()
		
		result.name = name
		result.type = type
		result.value_expr = value_expr
		result.is_static = is_static
		result.is_const = is_const
		
		assert(not (is_static == true and is_const == true), "Variables can't be static and const at the same time!")
		
		return result


class FuncArg:
	var name: String
	var type: GodotType = Type.Dynamic
	
	var required: bool = true
	var default_expr: String = ''
	
	static func create(name: String, type: GodotType = Type.Dynamic, required: bool = false, default_expr: String = '') -> FuncArg:
		var result: FuncArg = FuncArg.new()
		result.name = name
		result.type = type
		result.required = required
		result.default_expr = default_expr
		
		if not required and default_expr == '':
			result.default_expr = type.get_default_expr()
		
		return result


class Function:
	var name: String
	var return_type: GodotType = Type.Void
	var args: Array[FuncArg] = []
	
	var is_static: bool = false
	var is_async: bool = false
	
	static func create(name: String, return_type: GodotType = Type.Void, args: Array[FuncArg] = [],
			is_static: bool = false, is_async: bool = false):
		var result: Function = Function.new()
		result.name = name
		result.return_type = return_type
		# Make sure optional arguments are placed at the end
		#args.sort_custom(
			#func(arg_a, arg_b):
				#return not arg_b.required
		#)
		result.args = args
		result.is_static = is_static
		result.is_async = is_async
		return result
	
	func add_arg(arg: FuncArg) -> void:
		self.args.push_back(arg)
	
	func _has_arg_with_name(name: String) -> bool:
		for arg in self.args:
			if arg.name == name:
				return true
		return false


class Field:
	var name: String
	var type: GodotType
	
	var is_static: bool = false
	var value_expr: String = ''
	
	static func create(name: String, type: GodotType = Type.Dynamic, value_expr: String = '', is_static: bool = false) -> Field:
		var result: Field = Field.new()
		
		if name == '':
			push_warning("Name for field is empty! Replacing it with `result`")
			result.name = "result"
		else:
			result.name = name
		result.type = type
		result.value_expr = value_expr
		result.is_static = is_static
		
		return result


class Class:
	var name: String
	var type: GodotType
	
	var fields: Array[Field] = []
	var methods: Array[Function] = []
	
	static func create(name: String, fields: Array[Field] = [], methods: Array[Function] = []) -> Class:
		var result: Class = Class.new()
		result.name = name
		result.type = Type.class_(name)
		result.fields = fields
		result.methods = methods
		return result
	
	func add_field(field: Field) -> void:
		self.fields.push_back(field)
	
	func add_method(method: Function) -> void:
		self.methods.push_back(method)
