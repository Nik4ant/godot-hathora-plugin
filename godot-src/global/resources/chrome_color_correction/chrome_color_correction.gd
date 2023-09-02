extends ColorRect

func _ready():
	self.visible = false;
	if OS.has_feature("web"):
		# NOTE: to solve bluriness in the chromium browsers use CSS:
		# image-rendering: pixelated;
		var is_chromium = JavaScriptBridge.eval("!!window.chrome", true);
		if is_chromium:
			self.visible = true;
