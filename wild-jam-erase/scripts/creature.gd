class_name Creature
extends CharacterBody2D

signal creature_selected(Creature, Vector2)
signal creature_highlighted(bool)
var index : Vector2

enum State { IDLE, WANDER, CAUGHT }
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
	modulate = Color(1, 1, 1, 0.1)
	connect("creature_highlighted", _on_creature_highlighted)

	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
	add_child(timer)
	timer.timeout.connect(_change_state)
	_start_idle()

func _on_creature_highlighted(state) -> void:
	modulate = Color(1, 1, 1, 0.1)
	current_state = State.IDLE
	$AnimatedSprite2D.play(&"idle")
	if (state): 
		current_state = State.CAUGHT
		$AnimatedSprite2D.play(&"caught")
		modulate = Color(1, 1, 1, 1)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouse:
		if event.is_pressed():
			creature_selected.emit(self, index)

func _change_state() -> void:
	if current_state == State.IDLE and randf() < wander_chance:
		current_state = State.WANDER
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		timer.start(base_wander_time + randf_range(-time_variation, time_variation))
	else:
		_start_idle()

func _start_idle() -> void:
	current_state = State.IDLE
	direction = Vector2.ZERO
	timer.start(base_idle_time + randf_range(-time_variation, time_variation))

func _physics_process(delta: float) -> void:
	if current_state == State.WANDER:
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
