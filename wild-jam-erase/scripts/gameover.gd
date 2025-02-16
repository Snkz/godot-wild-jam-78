extends CanvasLayer

signal restart()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent = self.get_parent()
	parent.connect("gameover", _on_gameover)

func _on_gameover(matched_count, game_time) -> void:
	get_tree().paused = true
	get_node("score").text = "MATCHED: " + str(matched_count) + " TIME: " + str(game_time)
	visible = true

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			get_tree().paused = false
			visible = false
			restart.emit()
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
