extends Area2D

func _ready() -> void:
	print("BUILT")
		
func _physics_process(delta: float) -> void:	
	var mouseposition = get_viewport().get_mouse_position()
	self.position = mouseposition

func _on_body_entered(body: Node2D) -> void:
	print("ENTERED", body, body.name)

func _on_body_exited(body: Node2D) -> void:
	print("EXIT", body, body.name)
