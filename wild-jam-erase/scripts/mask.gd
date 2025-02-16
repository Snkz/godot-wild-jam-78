extends AnimatedSprite2D

var player: Area2D
var collision: CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = self.get_node("../../player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	material.set_shader_parameter("holeCenter", player.global_position)
	material.set_shader_parameter("holeRadius", player.mask_radius)
