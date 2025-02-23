extends CanvasLayer
signal restart()

# Called when the node enters the scene tree for the first time.
var original_radius = 0;
var gameover_active = false
func _ready() -> void:
	var parent = self.get_parent()
	parent.connect("gameover", _on_gameover)
	var player = self.get_node("../player")
	original_radius = player.mask_radius
	gameover_active = false


func _on_gameover(matched_count, game_time, win) -> void:
	var parent = self.get_parent()
	parent.camera_shake.emit(0.5, 0.25)
	
	gameover_active = true
	get_tree().paused = true
	
	var seconds = int(game_time) % 60
	var milliseconds = int((game_time - int(game_time)) * 1000)

	var formatted_time = "%d.%03d" % [seconds, milliseconds]
	visible = true
	
	var win_panel = self.get_node("win_panel")
	var lose_panel = self.get_node("lose_panel")
	
	win_panel.visible = win
	lose_panel.visible = not win
	
	var text_node = get_node("text")
	text_node.visible = true
	
	var time_node = get_node("text/time")
	time_node.text = ""
	time_node.append_text("TIME: ")
	time_node.append_text(formatted_time)
	time_node.append_text(" seconds")
	time_node.newline()
	time_node.append_text("SCORE: ")
	time_node.append_text(str(matched_count))
	time_node.newline()
	typewriter(time_node, 0.75)

	
	var restart_node = get_node("text/restart")
	restart_node.text = ""
	restart_node.append_text("Press ENTER to restart")
	typewriter(restart_node, 0.05)
	
	var audio = self.get_node("audio_gameover")
	audio.play()
	
	var creatures = get_tree().get_nodes_in_group("creatures")
	for creature in creatures:
		creature.emit_signal("creature_gameover")
	
func _process(delta: float) -> void:
	if not gameover_active:
		return
		
	var player = self.get_node("../player")
	var foreground = self.get_node("../foreground")

	var increased_radius = 3000
	var lerp_speed = 2.0
	player.mask_radius = lerp(player.mask_radius, original_radius + increased_radius, lerp_speed * delta)
	
	foreground.get_child(0).material.set_shader_parameter("holeCenter", player.position)
	foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)

func _unhandled_input(event):
	if not gameover_active:
		return
		
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			var parent = self.get_parent()
			parent.camera_shake.emit(0.2, 0.2)
			
			visible = false
			var text_node = get_node("text")
			text_node.visible = false
			var player = self.get_node("../player")
			var foreground = self.get_node("../foreground")
			player.mask_radius = 0.0
			foreground.get_child(0).material.set_shader_parameter("holeCenter", player.position)
			foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)
			
			gameover_active = false
			get_tree().paused = false
			
			restart.emit()
		if event.pressed and not OS.get_name() == "Web" and event.keycode == KEY_ESCAPE:
			get_tree().quit()

func typewriter(node, duration) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(node, "visible_ratio", 1.0, duration).from(0.0)
