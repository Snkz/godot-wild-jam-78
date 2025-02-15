extends Node2D

@export var creature_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
# Create a new instance of the Mob scene.
	for i in range(10):
		for j in range(10):
			var creature = creature_scene.instantiate()
			var player_position = $player.position
			creature.position = Vector2(i * 100, j * 100)
			creature.name = "creature " + str(i) + str(j)

			# Spawn the creature by adding it to the Main scene.
			add_child(creature)
