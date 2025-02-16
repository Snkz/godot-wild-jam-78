class_name Creature
extends CharacterBody2D

signal creature_highlighted(bool)
signal nearest_creature_highlighted(bool)

var index : Vector2

enum State { IDLE, WANDER, CAUGHT, DUST }
var current_state = State.IDLE

@export var base_idle_time := 3.0
@export var base_wander_time := 2.0
@export var time_variation := 1.0
@export var speed := 30.0
@export var wander_chance := 0.3

var direction := Vector2.ZERO
var timer := Timer.new()

func _ready() -> void:
	randomize()

	connect("creature_highlighted", _on_creature_highlighted)
	connect("nearest_creature_highlighted", _on_nearest_creature_highlighted)


	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	add_child(timer)
	timer.timeout.connect(_change_state)
	_start_idle()

func _on_creature_highlighted(state) -> void:
	if current_state == State.DUST:
		return
		
	_start_idle()
	
	if (state): 
		current_state = State.CAUGHT
		$AnimatedSprite2D.play(&"caught")
		
func _on_nearest_creature_highlighted(state) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)

	if (state): 
		$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 1)

func _change_state() -> void:
	if current_state == State.DUST:
		return
	if current_state == State.IDLE and randf() < wander_chance:
		current_state = State.WANDER
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		timer.start(base_wander_time + randf_range(-time_variation, time_variation))
	else:
		_start_idle()

func _start_idle() -> void:
	current_state = State.IDLE
	$AnimatedSprite2D.play(&"idle")
	direction = Vector2.ZERO
	timer.start(base_idle_time + randf_range(-time_variation, time_variation))

func _start_dust() -> void:
	current_state = State.DUST
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	$AnimatedSprite2D.play(&"dust")
	await $AnimatedSprite2D.animation_finished  

	self.queue_free()

func _physics_process(delta: float) -> void:
	if current_state == State.WANDER:
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
