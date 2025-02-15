extends CharacterBody2D

func _mouse_enter() -> void:
	print("hello", self.name)
	
func _mouse_exit() -> void:
	print("bye", self.name)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouse:
		if event.is_pressed():
			print("DOWN", self.name)
