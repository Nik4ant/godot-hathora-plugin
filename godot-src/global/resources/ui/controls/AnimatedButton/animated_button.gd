class_name AnimatedButton extends Button


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	self.button_pressed = true
	await get_tree().process_frame
	# NOTE: I don't know why, but styles are getting messed up in the editor, 
	# so this is why this wierdness exists
	var style: StyleBoxTexture = preload("res://global/resources/ui/controls/AnimatedButton/normal_style_bugfix.tres")
	remove_theme_stylebox_override("normal")
	add_theme_stylebox_override("normal", style.duplicate())
	self.button_pressed = false
	
	self.pressed.connect(_on_pressed)


func _on_mouse_entered() -> void:
	if animation_player.is_playing():
		await animation_player.animation_finished
	animation_player.play("hover")


func _on_mouse_exited() -> void:
	if animation_player.is_playing():
		await animation_player.animation_finished
	animation_player.play("anti_hover")


func _on_pressed() -> void:
	$sfx_press.play()
