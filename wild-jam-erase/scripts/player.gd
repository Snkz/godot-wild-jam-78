extends CharacterBody2D

func _process(delta: float) -> void:
	var mouseposition = get_viewport().get_mouse_position()
	self.position = mouseposition
