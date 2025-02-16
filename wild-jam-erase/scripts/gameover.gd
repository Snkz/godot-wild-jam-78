extends CanvasLayer

signal restart()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent = self.get_parent()
	parent.connect("gameover", _on_gameover)

func _on_gameover() -> void:
	get_tree().paused = true
	print("GAMEOVER")
	visible = true

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			get_tree().paused = false
			visible = false
			restart.emit()
