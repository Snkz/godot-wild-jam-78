extends AnimatedSprite2D

var player: Area2D
var collision: CollisionShape2D

var original_radius = 100.0
@export var increased_radius = 50.0
var lerp_speed = 10.0
var is_increasing = false

func _ready() -> void:
	player = self.get_node("../../player")
	original_radius = player.mask_radius

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	if is_increasing:
		player.mask_radius = lerp(player.mask_radius, original_radius + increased_radius, lerp_speed * delta)
	else:
		player.mask_radius = lerp(player.mask_radius, original_radius, lerp_speed * delta)
	
	material.set_shader_parameter("holeCenter", player.global_position)
	material.set_shader_parameter("holeRadius", player.mask_radius)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_increasing = true
			else:
				is_increasing = false
