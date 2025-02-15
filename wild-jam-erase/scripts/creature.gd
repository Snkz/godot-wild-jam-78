class_name Creature
extends CharacterBody2D

signal creature_selected(Creature, Vector2)
var index : Vector2

#func _mouse_enter() -> void:
#	print("hello ", self.name)
	
#func _mouse_exit() -> void:
#	print("bye ", self.name)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouse:
		if event.is_pressed():
			creature_selected.emit(self, index)
			

func _on_ready() -> void:
	randomize()
	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
