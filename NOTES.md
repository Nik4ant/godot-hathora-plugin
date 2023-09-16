# Steps to add a new endpoint:
0) ctrl+c, ctrl+v an existing region
1) Rename region, function and response class
2) Change return type
3) Add a signal to HathoraEventBus and rename usages in both functions
4) Replace params in both functions, change HTTP request method + request params
5) Change response class fields + deserialization process
5.1) Replace ASSERT error messages
6) [Optional] Add custom hints
7) [Optional] Add custom error messages

## Things to improve:
- HUGE ISSUE! before connecting to api_response.request_finished signal
CHECK FOR ERRORS FIRST! (or maybe just ignore this - leave to the user, because error is printed anyway)
- SUPER IDEA! MAKE A SINGLE AUTOLOAD!!
Hathora <-- single autoload that contains everything
Hathora.event_bus
[Put HathoraConstants inside Hathora]
Hathora.Auth.V1
[Somehow put enums as well, like: Hathora.Error.Ok ? idk]
- Keep in mind that docs should look nice: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_documentation_comments.html
+ Don't forget about the English recomendations as well

## Things that should be mentioned in docs:
- HathoraClient.init() MUST be called only once. (Otherwise it would be ignored)
- HathoraError enum has to be manually preloaded in order to check for detailed errors, BUT if you simply want to check if operation succeded you can use built-in OK defined @GlobalScope

## Godot limitations
There are some things that could make API better, but due to Godot lacking some
features this is simply not available :(

This section is used to keep track of those features in case some of them get fixed/changed in the newer Godot versions:
- enums can't be accessed without preloading the script
- Timers can't be created using code only without access to SceneTree