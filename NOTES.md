## Things that should be mentioned in docs:
- HathoraClient.init() MUST be called only once. (Otherwise it would be ignored)
- HathoraError enum has to be manually preloaded in order to check for detailed errors, BUT if you simply want to check if operation succeded you can use built-in OK defined @GlobalScope

## Godot limitations
There are some things that could make API better, but due to Godot lacking some
features this is simply not available :(

This section is used to keep track of those features in case some of them get fixed in the newer Godot versions:
- enums can't be accessed without preloading the script