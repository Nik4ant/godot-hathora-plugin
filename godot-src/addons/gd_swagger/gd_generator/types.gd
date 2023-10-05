#region     -- Default types
static var GodotBool: GodotType = GodotType.create("bool", TypeId.Bool)
static var GodotFloat: GodotType = GodotType.create("float", TypeId.Float)
static var GodotInt: GodotType = GodotType.create("int", TypeId.Int)
static var GodotString: GodotType = GodotType.create("String", TypeId.Str, GodotType.create("String", TypeId.Str))
static var GodotDictionary: GodotType = GodotType.create("Dictionary", TypeId.Dict)
static var GodotArray: GodotType = GodotType.create("Array", TypeId.Dict)
static var GodotSignal: GodotType = GodotType.create("Signal", TypeId.Class)
static var GodotClass: GodotType = GodotType.create("class", TypeId.Class)
static var Void: GodotType = GodotType.create("void", TypeId.Void)
#endregion  -- Default types


enum TypeId {
	Void = TYPE_NIL,
	Bool = TYPE_BOOL,
	Int = TYPE_INT,
	Float = TYPE_FLOAT,
	Str = TYPE_STRING,
	Array = TYPE_ARRAY,
	Dict = TYPE_DICTIONARY,
	Class = TYPE_OBJECT,
	Signal = TYPE_SIGNAL
}

class GodotType:
	var name: String
	var id: TypeId
	## Used for subtypes like Array[InnerType].
	## (Completely optional)
	var inner_sub_type: GodotType = null
	
	static func create(name: String, id: TypeId, inner_type: GodotType = null) -> GodotType:
		var result: GodotType = GodotType.new()
		result.name = name
		result.id = id
		result.inner_sub_type = inner_type
		return result
