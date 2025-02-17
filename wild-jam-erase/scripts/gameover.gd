extends CanvasLayer
signal restart()

# Called when the node enters the scene tree for the first time.
var original_radius = 0;
func _ready() -> void:
	var parent = self.get_parent()
	parent.connect("gameover", _on_gameover)
	var player = self.get_node("../player")
	original_radius = player.mask_radius

func _on_gameover(matched_count, game_time) -> void:
	get_tree().paused = true
	get_node("score").text = "MATCHED: " + str(matched_count) + " TIME: " + str(game_time)
	visible = true
	
	var audio = self.get_node("audio_gameover")
	audio.play()
	
	var creatures = get_tree().get_nodes_in_group("creatures")
	for creature in creatures:
		creature.emit_signal("creature_gameover")
	
func _process(delta: float) -> void:
	var player = self.get_node("../player")
	var foreground = self.get_node("../foreground")

	var increased_radius = 3000
	var lerp_speed = 2.0
	player.mask_radius = lerp(player.mask_radius, original_radius + increased_radius, lerp_speed * delta)
	
	foreground.get_child(0).material.set_shader_parameter("holeCenter", player.global_position)
	foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			visible = false
			var player = self.get_node("../player")
			var foreground = self.get_node("../foreground")
			player.mask_radius = 0.0
			foreground.get_child(0).material.set_shader_parameter("holeCenter", player.global_position)
			foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)
				
			var audio = self.get_node("audio_restart")
			audio.play()
			
			get_tree().paused = false
			
			restart.emit()
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
