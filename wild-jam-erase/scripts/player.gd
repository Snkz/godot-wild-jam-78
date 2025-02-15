extends Area2D

func _ready() -> void:
	print("BUILT")
		
func _physics_process(delta: float) -> void:	
	var mouseposition = get_viewport().get_mouse_position()
	self.position = mouseposition

func _on_body_entered(body: Node2D) -> void:
	body.emit_signal("creature_highlighted", true)


func _on_body_exited(body: Node2D) -> void:
	body.emit_signal("creature_highlighted", false)
