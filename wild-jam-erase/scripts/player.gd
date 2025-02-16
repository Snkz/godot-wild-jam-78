extends Area2D

signal creature_selected(Creature, Vector2)
var nearest_selection = null
var nearest_threshold = 1.0
var active_bodies = []

func set_nearest() -> void:
	var current_selection = null
	
	for body in active_bodies:
		var current_distance = nearest_selection.position.distance_to(self.position) if nearest_selection else 100000.0
		var body_distance = body.position.distance_to(self.position)
		if current_distance > (body_distance + nearest_threshold):
			current_selection = body
	
	if current_selection:
		if nearest_selection:
			nearest_selection.emit_signal("nearest_creature_highlighted", false)
			
		nearest_selection = current_selection
		nearest_selection.emit_signal("nearest_creature_highlighted", true)
		
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouse:
		if event.is_pressed() and nearest_selection:
			creature_selected.emit(nearest_selection, nearest_selection.index)

func _on_body_entered(body: Node2D) -> void:
	body.emit_signal("creature_highlighted", true)
	active_bodies.push_back(body)

func _on_body_exited(body: Node2D) -> void:
	body.emit_signal("creature_highlighted", false)
	active_bodies.erase(body)
	
	if body == nearest_selection:
		nearest_selection.emit_signal("nearest_creature_highlighted", false)
		nearest_selection = null
		
func _physics_process(delta: float) -> void:	
	var mouseposition = get_viewport().get_mouse_position()
	self.position = mouseposition
	set_nearest()
