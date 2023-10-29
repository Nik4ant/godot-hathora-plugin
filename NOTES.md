Funny code-gen errors:
```
func login_nickname(nickname: String) -> Signal:
	login_nickname_async(<RefCounted#-9223371991673731738>)
	return HathoraEventBus.on_login_nickname
```
```
for part in data["result"]:
	self.result.push_back(Array.deserialize(part))
```
```
for part in data["cpu"]:
	self.cpu.push_back(String.deserialize(part))
```

# Crazy ideas:
1) Monads!!!!!


## Things to improve:
- Some parameters are meant to be serialized (for example, RoomConfig)
They have type = "string", but for better UX on Godot side they should be
treated as Dictionary
- HUGE ISSUE! before connecting to api_response.request_finished signal
CHECK FOR ERRORS FIRST! (or maybe just ignore this - leave to the user, because error is printed anyway)
- Keep in mind that docs should look nice: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
+ Don't forget about the English recomendations as well

## Things that should be mentioned in docs:
- HathoraClient.init() MUST be called only once. (Otherwise it would be ignored)
- [Outdated] HathoraError enum has to be manually preloaded in order to check for detailed errors, BUT if you simply want to check if operation succeded you can use built-in OK defined @GlobalScope
- OPTIMAZATIONS! During the export code generator + some other parts can be excluded
## Godot limitations
There are some things that could make API better, but due to Godot lacking some
features this is simply not available :(

This section is used to keep track of those features in case some of them get fixed/changed in the newer Godot versions:
- enums can't be accessed without preloading the script
- Timers can't be created without access to SceneTree