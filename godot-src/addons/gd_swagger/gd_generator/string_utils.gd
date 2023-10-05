static func repeat(char: String, amount: int) -> String:
	var result: String = ''
	for _i in range(amount):
		result += char
	return result
