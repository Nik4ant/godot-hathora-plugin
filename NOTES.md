# Ideas
- Generate SDK for all target platforms (Unity, UE, Godot, custom?)
- Have a context specific error messages/hints (aka potential causes of the problem)

## Things to improve:
- Some parameters are meant to be serialized (for example, RoomConfig)
They have type = "string", but for better UX on Godot side they should be
treated as Dictionary
- Keep in mind that docs should look nice: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
+ Don't forget about the English recomendations as well

## Things that should be mentioned in docs:
- HathoraClient.init() MUST be called only once. (Otherwise it would be ignored)
- OPTIMAZATIONS! During the export unused endpoints can be excluded
