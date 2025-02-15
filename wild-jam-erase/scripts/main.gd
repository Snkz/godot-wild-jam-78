extends Node2D

@export var creature_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_res = get_viewport().get_visible_rect().size
	print ("SCREEN RES", screen_res)

	for i in range(1, 10):
		for j in range(1, 10):
			var creature = creature_scene.instantiate()
			creature.position = Vector2(i * 100, j * 100)
			creature.name = "creature " + str(i) + ":" + str(j)

			# Spawn the creature by adding it to the Main scene.
			add_child(creature)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
