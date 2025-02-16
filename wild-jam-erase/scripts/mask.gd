extends ColorRect

var player: Area2D
var collision: CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_node("../../player")
	if player:
		collision = player.get_node("CollisionShape2D")
		print(collision.shape.radius)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		material.set_shader_parameter("holeCenter", player.global_position)
		material.set_shader_parameter("holeRadius", collision.shape.radius)
