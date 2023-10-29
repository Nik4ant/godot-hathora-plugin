const Types = GD.Types
const Primitives = GD.Primitives


class CodeWriter:
	var offset: int = 0
	var code: String = ''
	var current_class: Primitives.Class = null
	var current_func: Primitives.Function = null
	
	func clear() -> void:
		self.offset = 0
		self.code = ''
		self.current_class = null
		self.current_func = null
	
	func build(output_file_path: String = '') -> String:
		if output_file_path != '':
			var file = FileAccess.open(output_file_path, FileAccess.WRITE)
			var error: Error = FileAccess.get_open_error()
			if error != OK:
				push_error(error_string(error))
			else:
				file.store_string(self.code)
			
			file.close()
		
		return self.code
	
	func _offset() -> String:
		return '\t'.repeat(self.offset)
	
	func comment(text: String, use_double_hashtag: bool = false, spaces_before_comment: int = 0) -> CodeWriter:
		self.code += _offset() + ' '.repeat(spaces_before_comment) + '#'
		
		self.code += '#' if use_double_hashtag else ' '
		self.code += text
		
		return self
	
	func eol(use_offset: bool = false) -> CodeWriter:
		if use_offset:
			self.code += _offset()
		self.code += '\n'
		return self
	
	func end_statement() -> CodeWriter:
		self.offset -= 1
		self.code += _offset() + '\n'
		
		return self
	
	func end_decl(add_newline: bool = true) -> CodeWriter:
		self.offset -= 1
		self.code += _offset() + '\n' if add_newline else ''
		
		if self.current_func != null:
			self.current_func = null
		elif self.current_class != null:
			self.current_class = null
		
		return self
	
	func end_all() -> CodeWriter:
		self.offset = 0
		self.code += '\n'
		
		if self.current_func != null:
			self.current_func = null
		if self.current_class != null:
			self.current_class = null
		
		return self
	
	func expr(expression: String) -> CodeWriter:
		self.code += expression
		return self
	
	func array_expr(values_expressions: Array[String], use_newlines: bool = false) -> CodeWriter:
		self.code += _offset() + '['
		
		if use_newlines:
			self.offset += 1
			self.code += '\n'
			for value in values_expressions:
				self.code += _offset() + value + ",\n"
			self.code = self.code.trim_suffix(",\n")
		else:
			for value in values_expressions:
				self.code += value + ", "
			self.code = self.code.trim_suffix(", ")
		
		self.code += ']'
		return self
	
	func dict_expr(expressions: Dictionary, use_newlines: bool = false, extra_content_offset: int = 0) -> CodeWriter:
		self.offset += extra_content_offset
		self.code += _offset() + '{'
		
		if use_newlines:
			self.offset += 1
			self.code += '\n'
			for key_expr in expressions.keys():
				self.code += _offset() + key_expr + ": " + expressions[key_expr] + ",\n"
			self.code = self.code.trim_suffix(",\n")
			self.offset -= 1
			self.code += '\n'
		else:
			for key_expr in expressions.keys():
				self.code += key_expr + ": " + expressions[key_expr] + ", "
			self.code = self.code.trim_suffix(", ")
		
		self.code += _offset() + '}'
		self.offset -= extra_content_offset
		return self
	
	func codeline(line: String) -> CodeWriter:
		self.code += _offset() + line + '\n'
		return self
	
	func insert_codeline(line_index: int, line: String) -> CodeWriter:
		assert(line_index < self.code.countn('\n'))
		
		var index: int = -1
		for i in range(line_index):
			index = self.code.findn('\n', index + 1)
		
		self.code = self.code.insert(index, '\n' + line)
		return self
	
	func variable(gd_var: Primitives.Variable) -> CodeWriter:
		self.code += _offset()
		
		if gd_var.is_static:
			self.code += "static "
		else:
			self.code += "const " if gd_var.is_const else "var "
		
		self.code += gd_var.name
		
		if Types.GodotType._is_static(gd_var.type):
			self.code += ": " + gd_var.type.build()
		# value
		if gd_var.value_expr != '':
			self.code += " = " + gd_var.value_expr
		
		return self
	
	static func _function(offset: int, function: Primitives.Function) -> String:
		var result: String = ''
		# func name(
		result += '\t'.repeat(offset) + "func " + function.name + '('
		# [args]
		for arg in function.args:
			result += arg.name
			if arg.type != Types.Dynamic:
				result += ": " + arg.type.build()
			if not arg.required:
				result += " = " + arg.default_expr
			result += ", "
		result = result.trim_suffix(", ")
		# ) -> [return_type]
		result += ')'
		if function.return_type != Types.Dynamic:
			result += " -> " + function.return_type.build()
		result += ":\n"
		return result
	
	func func_decl(name: String, return_type: Types.GodotType = Types.Void, 
			args: Array[Primitives.FuncArg] = [], is_static: bool = false, is_async: bool = false) -> CodeWriter:
		self.current_func = Primitives.Function.create(
			name, return_type, args, is_static, is_async
		)
		self.code += _function(self.offset, self.current_func)
		self.offset += 1
		
		return self

	func func_call(function: Primitives.Function, args_exprs: Array[String], use_await: bool = false) -> CodeWriter:
		self.code += _offset()
		
		if use_await:
			self.code += "await "
		
		self.code += function.name + '('
		for param in args_exprs:
			self.code += param + ", "
		self.code = self.code.trim_suffix(", ") + ')'
		
		return self
	
	func class_decl(cls_name: String) -> CodeWriter:
		self.current_class = Primitives.Class.create(cls_name)
		# class decl
		self.code += str(_offset(), "class ", cls_name, ":\n")
		self.offset += 1
		return self
	
	func add_field(name: String, type: Types.GodotType = Types.Dynamic, value_expression: String = '', is_static: bool = false) -> CodeWriter:
		assert(self.current_class != null, "Can't add field - define a class first!")
		
		var new_field = Primitives.Field.create(name, type, value_expression, is_static)
		self.current_class.add_field(
			new_field
		)
		
		self.code += '\t'.repeat(self.offset)
		if is_static:
			self.code += "static "
		
		self.code += "var " + new_field.name
		
		if type != Types.Dynamic:
			self.code += ": " + type.build()
		
		if value_expression != '':
			self.code += " = " + value_expression
		
		self.code += '\n'
		return self
	
	func add_method(name: String, return_type: Types.GodotType = Types.Void, args: Array[Primitives.FuncArg] = [],
			is_static: bool = false, is_async: bool = false) -> CodeWriter:
		assert(self.current_class != null, "Can't add method - define a class first!")
		var new_method: Primitives.Function = Primitives.Function.create(
			name, return_type, args, is_static, is_async
		)
		self.current_class.add_method(new_method)
		
		self.code += CodeWriter._function(self.offset, new_method)
		self.offset += 1
		
		return self
	
	func if_statement(condition_expr: String) -> CodeWriter:
		self.code += _offset() + "if " + condition_expr + ":\n"
		self.offset += 1
		return self
	
	func elif_statement(condition_expr: String) -> CodeWriter:
		self.offset -= 1
		self.code += _offset() + "elif " + condition_expr + ":\n"
		self.offset += 1
		return self
	
	func else_statement() -> CodeWriter:
		self.offset -= 1
		self.code += _offset() + "else:\n"
		self.offset += 1
		return self
	
	func for_statement(inner_var_expr: String, iter_expr: String) -> CodeWriter:
		self.code += _offset() + "for " + inner_var_expr + " in " + iter_expr + ":\n"
		self.offset += 1
		return self
