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

# To-Do + Discuss with Hathora devs:
- If known enum variable was detected (visibility, region, etc.) deserialize it to enum
(maybe optionally provide raw string value with raw_visibility, raw_region?)
- **CRITICAL** Make sure bug with data var and multiple arrays is fixed
- Add check in the deserialization logic (assert class type is preloaded)
- ApplicationWithDeployment, Invoice, Build, Deployment, LobbyV3, ProcessWithRooms, Process, RoomWithoutAllocations
 are stuck trying to deserialize itself
(**NOTE**: Some of those cases are most likely comming from ok responses, which contain Array of X, where X is the target type)
- Common type deserialization method is ALWAYS STATIC AND RETURNS A RESULT. FUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
- CardPaymentMethod + AchPaymentMethod + LinkPaymentMethod are wierdly connected and probably recursive
- Class names are inccorect (see MetricValue)


## Things to improve?:
- Some parameters are meant to be serialized (for example, RoomConfig)
They have type = "string", but for better UX on Godot side they should be
treated as Dictionary
- Keep in mind that docs should look nice: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
+ Don't forget about the English recomendations as well

## Things that should be mentioned in docs:
- HathoraClient.init() MUST be called only once. (Otherwise it would be ignored)
- OPTIMAZATIONS! During the export code generator + some other parts can be excluded
## Godot limitations
There are some things that could make API better, but due to Godot lacking some
features this is simply not available :(

This section is used to keep track of those features in case some of them get fixed/changed in the newer Godot versions:
- enums can't be accessed without preloading the script (see error.gd)
- Timers can't be created without access to the SceneTree (Room's get_connection_info)