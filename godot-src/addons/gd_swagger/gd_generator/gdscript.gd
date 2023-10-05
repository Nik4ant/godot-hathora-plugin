extends Node

const StrUtils = preload("res://addons/gd_swagger/gd_generator/string_utils.gd")
const Types = preload("res://addons/gd_swagger/gd_generator/types.gd")
const GodotType = Types.GodotType


class GodotVariable:
	var name: String
	## Can be null
	var type: GodotType
	
	var is_const: bool = false
	var is_static: bool = false
	
	var value_expression: String
	
	static func create(name: String, type: GodotType = null, value_expression: String = '',
			is_const: bool = false, is_static: bool = false) -> GodotVariable:
		var result: GodotVariable = GodotVariable.new()
		result.name = name
		result.value_expression = value_expression
		if type != null:
			result.type = type
		
		result.is_const = is_const
		if is_const:
			assert(value_expression != '', "ASSERT! Const value can't be empty (techniqually it can, but it doesn't make sense)")
			assert(not is_static, "ASSERT! Const variables are static by nature")
		result.is_static = is_static
		
		return result
	
	func build() -> String:
		var result: String = ""
		if self.is_const:
			result += "const"
			return "const {name}: {type} = {value}".format({
				"name": self.name, "type": self.type.get_name(), "value": self.value_expression
			})
		if self.is_static:
			result += "static"
		
		result += "{name}: {type}".format({
			"name": self.name, "type": self.type.get_name()
		})
		if self.value_expression != '':
			result += "= " + self.value_expression
		
		return result


class GodotFunctionArg:
	var name: String
	var type: GodotType
	
	var optional: bool = false
	var default_value_expression: String = ''
	
	func build() -> String:
		if self.optional:
			return self.name + ": " + self.type.get_name() + " = " + self.default_value_expression
		return self.name + ": " + self.type.get_name()


class GodotFunction:
	var name: String
	var args: Array[GodotFunctionArg]
	var return_type: GodotType
	# Defined outside
	# Note: Bad, I know, but works for now
	var implementation: String = ''
	
	func build(tabs_offset: int) -> String:
		# Defenition
		var args_code: String = '('
		for arg in self.args:
			args_code += arg.build() + ", "
		args_code = args_code.rstrip(", ") + ')'
		
		var result: String = str(
			"func ", self.name, args_code, 
			" -> ", self.return_type.get_name(), ':'
		)
		# Implementation
		if self.implementation != '':
			var offset: int = tabs_offset
			offset += 1
			result += StrUtils.repeat('\t', offset) + implementation + '\n'
			offset -= 1
			result += StrUtils.repeat('\t', offset) + '\n'
		
		return result
	
	static func create(func_name: String, type: GodotType) -> GodotFunction:
		var result: GodotFunction = GodotFunction.new()
		result.name = func_name
		result.return_type = type
		return result
	
	func add_arg(arg_name: String, arg_type: GodotType, optional: bool = false, default_value_expr: String = '') -> GodotFunction:
		var arg: GodotFunctionArg = GodotFunctionArg.new()
		arg.name = arg_name
		arg.type = arg_type
		arg.optional = false
		arg.default_value_expression = default_value_expr
		return self
	
	func add_args(args: Array[GodotFunctionArg]) -> GodotFunction:
		self.args.append_array(args)
		return self


class GodotField:
	var name: String
	var type: GodotType
	
	func build() -> String:
		# Typing is optional, so...
		if type != null:
			return "var " + self.name + ": " + self.type.get_name()
		return "var " + self.name


class GodotClass:
	var self_type: GodotType
	var name: String
	var fields: Array[GodotField] = []
	var methods: Array[GodotFunction] = []
	
	static func create(gd_class_name: String) -> GodotClass:
		var result = GodotClass.new()
		result.name = gd_class_name
		result.self_type = GodotType.create(gd_class_name, Types.TypeId.Class)
		return result
	
	func build(tabs_offset: int) -> String:
		var offset: int = tabs_offset
		
		# Class defenition
		var result = str(
			StrUtils.repeat('\t', offset), 
			"class ", self.name, ":\n"
		)
		offset += 1
		# Fields
		for field in self.fields:
			result += StrUtils.repeat('\t', offset) + field.build() + '\n'
		result += StrUtils.repeat('\t', offset) + '\n'
		# Methods
		for method in self.methods:
			result += StrUtils.repeat('\t', offset) + method.build(offset) + '\n'
			result += StrUtils.repeat('\t', offset) + '\n'

		return result
	
	func add_field(field_name: String, field_type: GodotType = null) -> GodotClass:
		var field: GodotField = GodotField.new()
		field.name = field_name
		field.type = field_type
		self.fields.push_back(field)
		return self
	
	func add_method(method: GodotFunction) -> GodotClass:
		self.methods.push_back(method)
		return self


class Generator:
	var code: String
	## Indicates current offset in \t
	var current_offset: int = 0
	
	var current_function: GodotFunction = null
	var current_class: GodotClass = null
	
	## Key: String (name); Value: GodotVariable (variable)
	var existing_vars: Dictionary = {}
	## Key: String (name); Value: GodotFunction (function)
	var existing_functions: Dictionary = {}
	## Key: String (name); Value: GodotClass (class)
	# NOTE: USE IT TO CHECK FOR CUSTOM TYPES
	var existing_classes: Dictionary = {}
	
	func add_comment(comment: String, use_offset: bool = true) -> Generator:
		if use_offset:
			self.code += StrUtils.repeat('\t', self.current_offset)
		self.code += '#' + comment
		return self.add_newlines()
	
	func add_newlines(amount: int = 1, use_offset: bool = false) -> Generator:
		if use_offset:
			self.code += StrUtils.repeat('\t', self.current_offset)
		for _i in range(amount):
			self.code += '\n'
		return self
	
	## Adds a single codeline (takes into account current context)
	func add_codeline(line: String) -> Generator:
		var new_line: String = StrUtils.repeat('\t', self.current_offset) + line
		if self.current_function != null:
			self.current_function.implementation += new_line + '\n'
		self.code += new_line
		return self.add_newlines()
	
	func add_var(new_var: GodotVariable) -> Generator:
		if self.existing_vars.has(new_var.name):
			push_error("Variable with name: `", new_var.name, "` already exists")
			breakpoint
		self.existing_vars[new_var.name] = new_var
		
		self.code += StrUtils.repeat('\t', self.current_offset) + new_var.build()
		
		return self.add_newlines()
	
	func add_if(condition: String) -> Generator:
		self.code += StrUtils.repeat('\t', self.current_offset) + "if " + condition + ":"
		self.current_offset += 1
		return self.add_newlines()
	
	func add_elif(condition: String) -> Generator:
		self.current_offset -= 1
		self.code += StrUtils.repeat('\t', self.current_offset) + "elif " + condition + ":"
		self.current_offset += 1
		return self.add_newlines()
	
	func add_else() -> Generator:
		self.current_offset -= 1
		self.code += StrUtils.repeat('\t', self.current_offset) + "else:"
		self.current_offset += 1
		return self.add_newlines()
	
	func end_if_decl() -> Generator:
		self.current_offset -= 1
		return self.add_newlines()
	
	func add_for_range(inner_var_name: String, min: int, max: int, step: int) -> Generator:
		return self.add_for(
			inner_var_name, "range({min}, {max}, {step})".format(
				{"min": min, "max": max, "step": step}
			)
		)
	
	func add_for(inner_var_name: String, source_expression: String) -> Generator:
		self.code += str(
			StrUtils.repeat('\t', self.current_offset), 
			"for ", inner_var_name, " in ", source_expression, ":"
		)
		self.current_offset += 1
		return self.add_newlines()
	
	func end_for_decl() -> Generator:
		self.current_offset -= 1
		return self.add_newlines()
	
	func add_function(function: GodotFunction) -> Generator:
		self.code += StrUtils.repeat('\t', self.current_offset) + function.build(0)
		self.current_offset += 1
		self.current_function = function
		if self.current_class != null:
			self.current_class.add_method(function)
			
		return self.add_newlines()
	
	## Identifies that func defenition is over
	func end_func_decl() -> Generator:
		self.current_function = null
		self.current_offset -= 1
		return self.add_newlines(1, true)
	
	func add_class(godot_class: GodotClass) -> Generator:
		self.code += godot_class.build(self.current_offset)
		self.current_offset += 1
		self.current_class = godot_class
		return self.add_newlines()
	
	## Identifies that class defenition is over
	func end_class_decl() -> Generator:
		self.current_class = null
		self.current_offset -= 1
		return self.add_newlines(1, true)
	
	func build(output_filename: String = '') -> String:
		if output_filename != '':
			print("TODO: write code inside of a file")
		
		return self.code
