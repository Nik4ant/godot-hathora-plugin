## Does a series of get calls on a Dictionary 
## using keys from [param path] splitted by [param separator]
## (Returns [param default_value] if [param path] is invalid)
static func safe_get(dict: Dictionary, path: String, default_value = null, separator: String = '/'):
	var result = dict
	
	for key in path.split(separator):
		result = result.get(key, null)
		if result == null:
			return default_value
	return result
