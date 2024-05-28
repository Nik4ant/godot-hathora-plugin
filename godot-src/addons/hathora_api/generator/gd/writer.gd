const Types = GD.Types


class BaseContext:
	var code: String = ''
	var initial_offset: int = 0
	var offset: int = 0
	
	signal context_finished(old_context: BaseContext)
	
	func _init(initial_offset: int = 0, initial_code: String = '') -> void:
		self.offset = initial_offset
		self.initial_offset = initial_offset
		self.code = initial_code
		
		context_finished.connect(__on_context_finished)
	
	func __on_context_finished(old_context: BaseContext) -> void:
		code += old_context.code
	
	#region Basic
	func clear() -> MainWriter:
		self.offset = 0
		self.code = ''
		return self
	
	func _offset() -> String:
		return '\t'.repeat(self.offset)
	
	func insert_eol(at: int) -> MainWriter:
		return self.insert_codeline(at, '')
	
	func eol(use_offset: bool = false) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		self.code += '\n'
		
		return self
	
	func comment(text: String, is_doc_comment: bool = false, use_offset: bool = true, spaces_after: int = 1, spaces_before: int = 0) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		
		self.code += ' '.repeat(spaces_before) + '#'
		if is_doc_comment:
			self.code += '#'
		
		self.code += ' '.repeat(spaces_after) + text
		
		return self
	
	func codeline(line: String, use_eol: bool = true) -> MainWriter:
		self.code += self._offset() + line
		if use_eol:
			self.code += '\n'
		
		return self
	
	func insert_codeline(at: int, line: String) -> MainWriter:
		assert(at <= self.code.countn('\n'), "Line with index `" + str(at) + "` doesn't exist")
		
		var index: int = 0
		for i in range(at):
			index = self.code.findn('\n', index + 1)
		
		self.code = self.code.insert(index, '\n' + line)
		return self
	#endregion
	
	#region Calls
	func _func_call_str(target: Types.GodotFunction, args: Array[Types.TypedExpr], preffix: String = '') -> String:
		var result: String = preffix
		
		if target.is_async:
			result += "await "
		result += target.name + '('
		
		for i: int in range(args.size()):
			assert(
				target.args[i].type.equals(args[i].type), 
				"Argument `" + str(args[i]) + "` doesn't match the type " + str(target.args[i].type)
			)
			result += args[i].expr + ", "
		
		return result.trim_suffix(", ") + ")"
	
	## unsafe - doesn't check type signature and if function/method exists
	func call_unsafe(call_name_expression: String, args_expressions: Array[String], is_async: bool = false, use_offset: bool = false, use_eol: bool = false, eol_every_item: bool = false) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		
		if is_async:
			self.code += "await "
		self.code += call_name_expression + '('
		
		for expression: String in args_expressions:
			if eol_every_item:
				self.code += '\t' + expression + ", " + "\n\t"
			else:
				self.code += expression + ", "
		
		self.code = code.trim_suffix("\n\t").trim_suffix(", ") + ")"
		
		if use_eol:
			self.code += '\n'
		
		return self
	
	func call_direct(function: Types.GodotFunction, args: Array[Types.TypedExpr] = [], use_offset: bool = false, use_eol: bool = false) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		self.code += _func_call_str(function, args)
		if use_eol:
			self.code += '\n'
		
		return self
	#endregion
	
	#region Expressions
	func raw_expr(expression: String, use_offset: bool = false) -> MainWriter:
		if use_offset:
			self.code += _offset()
		self.code += expression
		return self
	
	func expr(expression: Types.TypedExpr) -> MainWriter:
		self.code += expression.value
		return self
	
	func arr_expr(values: Array[String], eol_every_item: bool = false, use_offset: bool = false) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		
		self.code += '['
		if eol_every_item:
			self.code += "\n\t"
		for value: String in values:
			if eol_every_item:
				self.code += self._offset() + '\t' + value + ", " + "\n\t"
			else:
				self.code += value + ", "
		
		if eol_every_item:
			self.code = self.code.trim_suffix('\t')
		self.code = self.code.trim_suffix(", ") + ']'
		
		return self
	
	func dict_expr(expressions: Dictionary, eol_every_item: bool = true, use_offset: bool = false, first_eol_tab: bool = true) -> MainWriter:
		if use_offset:
			self.code += self._offset()
		
		if eol_every_item and first_eol_tab:
			self.code += '\t'
		self.code += '{'
		
		if eol_every_item:
			self.code += "\n\t"
		
		for key: String in expressions.keys():
			var value: String = expressions[key]
			
			if eol_every_item:
				self.code += self._offset() + '\t' + key + ": " + value + ",\n\t"
			else:
				self.code += key + ": " + value + ", "
		
		if eol_every_item:
			self.code += self._offset()
		else:
			self.code = self.code.trim_suffix(", ")
		
		self.code += '}'
		
		return self
	#endregion


class MainWriter extends BaseContext:
	## All classes available in the current context
	## name: String; cls: Types.GodotClass
	var classes: Dictionary = {}
	var cur_class: Types.GodotClass = null
	## All functions available in the current context
	## name: String; function: Types.GodotFunction
	var functions: Dictionary = {}
	var cur_func: Types.GodotFunction = null
	
	#region Primitives (If/For/While/...)
	func if_(condition: String) -> MainWriter:
		self.code += _offset() + "if " + condition + ':'
		self.offset += 1
		return self
	
	func else_() -> MainWriter:
		self.offset -= 1
		self.code += _offset() + "else:"
		self.offset += 1
		return self
	
	## By default item type is defined by [param target] subtype, but
	## [param specific_item_type] is used instead if exists
	func for_in(item_name: String, target: Types.TypedExpr, specific_item_type: Types.GodotType = null) -> MainWriter:
		self.code += _offset() + "for " + item_name + ": "
		
		if specific_item_type != null:
			self.code += str(specific_item_type)
		else:
			if target.type.id == Types.Id.Array:
				assert(target.type.sub_type_value != null, "For loop can't iterate type `" + str(target.type) + '`')
				self.code += str(target.type.sub_type_value)
			else:
				assert(target.type.sub_type_key != null, "For loop can't iterate type `" + str(target.type) + '`')
				self.code += str(target.type.sub_type_key)
		
		self.code += " in " + target.value + ':'
		self.offset += 1
		
		return self
	
	func for_range(item_name: String, stop: Types.TypedExpr, start: Types.TypedExpr = null, step: Types.TypedExpr = null) -> MainWriter:
		assert(
			start.type.id == Types.Id.Int and stop.type.id == Types.Id.Int and step.type.id == Types.Id.Int, 
			"range(start, stop, step) accepts only integers!"
		)
		var expr: String = "range("
		if start != null:
			expr += start.value + ", "
		expr += stop.value
		if step != null:
			expr += ", " + step.value
		expr += ')'
		
		return for_in(item_name, Types.TypedExpr.new(expr, Types.array(Types.Int)))
	
	## Ends current block and goes to a new line
	func end() -> MainWriter:
		self.offset -= 1
		return self
	#endregion
	
	#region Class
	func add_class(cls_name: String) -> MainWriter:
		assert(!self.classes.has(cls_name), "Class with name: `" + cls_name + "` already exists")
		var cls = Types.GodotClass.new(cls_name)
		self.classes[cls_name] = cls
		self.cur_class = cls
		
		self.code += self._offset() + "class " + cls_name + ":\n"
		self.offset += 1
		
		return self
	
	func add_field(field: Types.GodotVariable) -> MainWriter:
		assert(self.cur_class != null and self.cur_func == null, "Can't add field in the current context")
		self.cur_class.add_property(field)
		self.code += self._offset() + str(field) + '\n'
		
		return self
	
	func add_method(function: Types.GodotFunction) -> MainWriter:
		assert(self.cur_class != null, "Can't add a method without a class!")
		self.cur_class.add_method(function)
		
		self.code += self._offset() + str(function) + '\n'
		self.offset += 1
		
		return self
	
	func end_class() -> MainWriter:
		self.cur_class = null
		self.offset -= 1
		return self
	
	func end_method() -> MainWriter:
		return end_func()
	#endregion
	
	#region Functions
	## Adds [param other_function] to the [member functions] without
	## inserting any code to the writer
	func add_func_reference(other_function: Types.GodotFunction) -> MainWriter:
		assert(!self.functions.has(other_function.name), "Function with name: `" + other_function.name + "` already exists")
		self.functions[other_function.name] = other_function
		return self
	
	func add_function(function: Types.GodotFunction) -> MainWriter:
		assert(!self.functions.has(function.name), "Function with name: `" + function.name + "` already exists")
		self.functions[function.name] = function
		self.cur_func = function
		
		self.code += self._offset() + str(function) + '\n'
		self.offset += 1
		
		return self
	
	func end_func() -> MainWriter:
		self.cur_func = null
		self.offset -= 1
		return self
	#endregion
	
	#region Other
	func add_var(variable: Types.GodotVariable, use_eol: bool = false) -> MainWriter:
		self.code += self._offset() + str(variable)
		if use_eol:
			self.code += '\n'
		
		return self
	#endregion
	
	#region Calls
	func call_name(func_name: String, args: Array[Types.TypedExpr] = [], use_offset: bool = false, use_eol: bool = false) -> MainWriter:
		assert(self.functions.has(func_name), "Function `" + func_name + "` doesn't exist")
		var target: Types.GodotFunction = self.functions[func_name]
		
		if use_offset:
			self.code += self._offset()
		self.code += _func_call_str(target, args)
		if use_eol:
			self.code += '\n'
		
		return self
	
	func call_method(object: Types.TypedExpr, method_name: String, args: Array[Types.TypedExpr] = [], use_offset: bool = true, use_eol: bool = true) -> MainWriter:
		assert(object.type.functions.has(method_name), "Specified object doesn't have method named `" + method_name + '`')
		var method: Types.GodotFunction = object.type.functions[method_name]
		
		if use_offset:
			self.code += self._offset()
		
		self.code += _func_call_str(method, args, object.value + '.')
		
		if use_eol:
			self.code += '\n'
		
		return self
	#endregion
	
	func finish(output_file_path: String = '') -> String:
		if output_file_path == '':
			return self.code
		
		DirAccess.make_dir_recursive_absolute(
			output_file_path.substr(0, output_file_path.rfind('/'))
		)
		
		var file = FileAccess.open(output_file_path, FileAccess.WRITE)
		var error: Error = FileAccess.get_open_error()
		if error != OK:
			push_error(error_string(error))
		else:
			file.store_string(self.code)
		
		file.close()
		
		return self.code


# NOTE: Context specific writer was scrapped
#region Unused-contexts
class ConditionContext:
	var from: MainWriter
	var code: String = ''
	
	func _init(old_context: MainWriter) -> void:
		self.from = from
	
	func expr(expr: String) -> ConditionContext:
		code += expr
		return self
	
	func done() -> MainWriter:
		from.context_finished.emit(self)
		return from
	
	func is_(other: String) -> ConditionContext:
		code += " is " + other
		return self
	
	#region logical ops
	func and_() -> ConditionContext:
		code += " and "
		return self
	
	func or_() -> ConditionContext:
		code += " or "
		return self
	
	func not_() -> ConditionContext:
		code += " not "
		return self
	#endregion
	
	#region bool ops
	## not equals !=
	func ne(other: String) -> ConditionContext:
		code += " != " + other
		return self
	
	## equals ==
	func eq(other: String) -> ConditionContext:
		code += " == " + other
		return self
	
	## greater than >
	func gt(other: String) -> ConditionContext:
		code += " > " + other
		return self
	
	## less than <
	func lt(other: String) -> ConditionContext:
		code += " < " + other
		return self
	
	## greater or equals >=
	func ge(other: String) -> ConditionContext:
		code += " >= " + other
		return self
	
	## less or equals <=
	func le(other: String) -> ConditionContext:
		code += " <= " + other
		return self
	#endregion


class VarContext:
	var from: MainWriter
	var code: String = ''
	var var_: Types.GodotVariable = null
	
	func _init(name: String, from_context: MainWriter = null) -> void:
		self.var_ = Types.GodotVariable.new(name)
	
	func static_() -> VarContext:
		var_.is_static = true
		return self
	
	func const_() -> VarContext:
		var_.is_const = true
		return self
	
	func type(type: Types.GodotType) -> VarContext:
		var_.type = type
		return self
	
	func value(value: String) -> MainWriter:
		var_.value = value
		code = value
		return from
	
	func to() -> Types.GodotVariable:
		return var_
#endregion
