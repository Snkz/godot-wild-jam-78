extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_res = DisplayServer.screen_get_size()
	self.position = screen_res / 2

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
