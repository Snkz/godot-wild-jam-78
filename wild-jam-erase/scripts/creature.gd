class_name Creature
extends CharacterBody2D

signal creature_highlighted(bool)
signal nearest_creature_highlighted(bool)
signal creature_matched(a, b, c)
signal creature_deleted(a, b)

var index : int

enum BehaviourState { IDLE, WANDER, CAUGHT, DUST, FEAR, CHASE }
var current_behaviour = BehaviourState.IDLE

@export var base_idle_time := 3.0
@export var time_variation := 1.0
@export var wander_speed := 30.0
@export var wander_chance := 0.3
@export var base_wander_time := 2.0
@export var chase_chance := 0.0
@export var chase_distance_min_threshold := 10
@export var chase_distance_max_threshold := 250
@export var chase_speed := 30.0
@export var base_chase_time := 1.0
@export var fear_chance := 0.0
@export var fear_speed := 30.0
@export var fear_distance_min_threshold := 50
@export var fear_distance_max_threshold := 200
@export var base_fear_time := 2.0
@export var explode_on_click := false

var tween_hover: Tween
var direction := Vector2.ZERO
var timer := Timer.new()

func _ready() -> void:
	randomize()
	
	connect("creature_highlighted", _on_creature_highlighted)
	connect("nearest_creature_highlighted", _on_nearest_creature_highlighted)
	connect("creature_matched", _on_creature_matched)

	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	$AnimatedSprite2D.material.set_shader_parameter("line_color", Vector4.ONE)
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	start_idle()

func _on_creature_highlighted(state) -> void:
	if current_behaviour == BehaviourState.DUST:
		return
	
	start_idle()
	
	if (state): 
		current_behaviour = BehaviourState.CAUGHT
		$AnimatedSprite2D.play(&"caught")
		
func _on_nearest_creature_highlighted(state) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	if tween_hover and tween_hover.is_running():
		tween_hover.kill()
	tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween_hover.tween_property(self, "scale", Vector2.ONE, 0.4)
	
	if (state): 
		$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 1)
		if tween_hover and tween_hover.is_running():
			tween_hover.kill()
		tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween_hover.tween_property(self, "scale", Vector2(1.1, 1.1), 0.6)

func _on_creature_matched(node, selected, matched) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	if selected:
		if explode_on_click:
			start_dust()
		else:
			$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 1)
	
	if (selected and matched):
		start_dust()
	
func _on_timeout() -> void:
	if current_behaviour == BehaviourState.DUST:
		return
	
	var result = init_chase() or init_fear() or init_wander()
	if not result:
		start_idle()

func start_idle() -> void:
	current_behaviour = BehaviourState.IDLE
	$AnimatedSprite2D.play(&"idle")
	direction = Vector2.ZERO
	timer.start(base_idle_time + randf_range(-time_variation, time_variation))

func start_dust() -> void:
	current_behaviour = BehaviourState.DUST
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	$AnimatedSprite2D.play(&"dust")
	await $AnimatedSprite2D.animation_finished  
	creature_deleted.emit(self, index)
	self.queue_free()

func init_wander() -> bool:
	if current_behaviour == BehaviourState.IDLE and randf() < wander_chance:
		current_behaviour = BehaviourState.WANDER
		direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		timer.start(base_wander_time + randf_range(-time_variation, time_variation))
		return true
	
	return false
	
func start_wander() -> void:
	velocity = direction * wander_speed
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
		

func init_chase() -> bool:
	var player = self.get_node("../../player")
	var distance = player.position.distance_to(self.position)
	if distance > chase_distance_min_threshold and distance < chase_distance_max_threshold and randf() < chase_chance:
		current_behaviour = BehaviourState.CHASE
		direction = (player.position - self.position).normalized()
		timer.start(base_chase_time + randf_range(-time_variation, time_variation))
		return true
		
	return false
	
func start_chase() -> void:
	velocity = direction * chase_speed
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	var player = self.get_node("../../player")
	var distance = player.position.distance_to(self.position)
	direction = (player.position - self.position).normalized()

	if distance <= 1.0 or distance >= chase_distance_max_threshold + 10.0:
		direction = Vector2.ZERO
	
func init_fear() -> bool:
	var player = self.get_node("../../player")
	var distance = player.position.distance_to(self.position)
	if distance > fear_distance_min_threshold and distance < fear_distance_max_threshold and randf() < fear_chance:
		current_behaviour = BehaviourState.FEAR
		direction = -1.0 * (player.position - self.position).normalized()
		timer.start(base_fear_time + randf_range(-time_variation, time_variation))
		return true
		
	return false
	
func start_fear() -> void:
	velocity = direction * fear_speed
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	var player = self.get_node("../../player")
	var distance = player.position.distance_to(self.position)
	direction = -1.0 * (player.position - self.position).normalized()

	if distance >= chase_distance_max_threshold + 10.0:
		direction = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if current_behaviour == BehaviourState.WANDER:
		start_wander()
	elif current_behaviour == BehaviourState.CHASE:
		start_chase()
	elif current_behaviour == BehaviourState.FEAR:
		start_fear()
	else:
		velocity = Vector2.ZERO
