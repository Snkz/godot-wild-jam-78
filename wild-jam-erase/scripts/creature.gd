class_name Creature
extends CharacterBody2D

signal creature_highlighted(bool)
signal nearest_creature_highlighted(bool)
signal creature_matched(a, b, c)
signal creature_deleted(a, b)


var index : int
var colour : Color

enum BehaviourState { IDLE, WANDER, CAUGHT, DUST, FEAR, CHASE, REVEAL, SELECTED }
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
@export var reveal_colour_on_click := false
@export var base_reveal_time := 1.0

var tween_hover: Tween
var direction := Vector2.ZERO
var timer = null

func _ready() -> void:
	randomize()
	timer = Timer.new()
	clear_reveal()
	
	connect("creature_highlighted", _on_creature_highlighted)
	connect("nearest_creature_highlighted", _on_nearest_creature_highlighted)
	connect("creature_matched", _on_creature_matched)

	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	start_idle()

func _on_creature_highlighted(state) -> void:
	if current_behaviour == BehaviourState.DUST:
		return
		
	if current_behaviour == BehaviourState.SELECTED:
		return
		
	if current_behaviour == BehaviourState.REVEAL:
		clear_reveal()
	
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
	
	if current_behaviour == BehaviourState.REVEAL:
		clear_reveal()
	
	if (state): 
		$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 1)
		if tween_hover and tween_hover.is_running():
			tween_hover.kill()
		tween_hover = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween_hover.tween_property(self, "scale", Vector2(1.1, 1.1), 0.6)
		
func _on_creature_matched(node, selected, matched) -> void:
	var creature_layer = get_parent()
	creature_layer.layer = 0
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	
	if selected:
		creature_layer.layer = 2
		if reveal_colour_on_click and not matched:
			current_behaviour = BehaviourState.SELECTED
			$AnimatedSprite2D.play(&"selected")

			start_reveal()
		elif explode_on_click:
			start_dust()
		else:
			current_behaviour = BehaviourState.SELECTED
			$AnimatedSprite2D.play(&"selected")
			timer.stop()
	else:
		if not matched and current_behaviour == BehaviourState.SELECTED:
			start_idle()

	if (selected and matched):
		start_dust()

func start_reveal() -> void:
	var canvas = self.get_parent().get_parent().get_parent()
	var ysort = self.get_parent().get_parent()
	for child in ysort.get_children():
		child.layer = 2
		
	canvas.layer = 2;
	current_behaviour = BehaviourState.REVEAL
	timer.start(base_reveal_time + randf_range(-time_variation, time_variation))

func clear_reveal() -> void:
	var canvas = self.get_parent().get_parent().get_parent()
	var ysort = self.get_parent().get_parent()
	for child in ysort.get_children():
		if self.get_parent() != child and current_behaviour != BehaviourState.SELECTED:
			child.layer = 0
	
	canvas.layer = 0;
	current_behaviour = BehaviourState.IDLE

func _on_timeout() -> void:
	if current_behaviour == BehaviourState.DUST:
		return
		
	if current_behaviour == BehaviourState.SELECTED:
		return
		
	if current_behaviour == BehaviourState.REVEAL:
		clear_reveal()
	
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
	creature_deleted.emit(self, index)
	await $AnimatedSprite2D.animation_finished  
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
	$AnimatedSprite2D.play(&"run")
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
		

func init_chase() -> bool:
	if current_behaviour != BehaviourState.IDLE and current_behaviour != BehaviourState.WANDER:
		return false
		
	var player = self.get_tree().root.get_node("main/player")
	var distance = player.position.distance_to(self.position)
	if distance > chase_distance_min_threshold and distance < chase_distance_max_threshold and randf() < chase_chance:
		current_behaviour = BehaviourState.CHASE
		direction = (player.position - self.position).normalized()
		timer.start(base_chase_time + randf_range(-time_variation, time_variation))
		return true
		
	return false
	
func start_chase() -> void:
	velocity = direction * chase_speed
	$AnimatedSprite2D.play(&"run")
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
	
	var player = self.get_tree().root.get_node("main/player")
	var distance = player.position.distance_to(self.position)
	direction = (player.position - self.position).normalized()

	if distance <= 1.0 or distance >= chase_distance_max_threshold + 10.0:
		direction = Vector2.ZERO
	
func init_fear() -> bool:
	if current_behaviour != BehaviourState.IDLE and current_behaviour != BehaviourState.WANDER:
		return false
	
	var player = self.get_tree().root.get_node("main/player")
	var distance = player.position.distance_to(self.position)
	if distance > fear_distance_min_threshold and distance < fear_distance_max_threshold and randf() < fear_chance:
		current_behaviour = BehaviourState.FEAR
		direction = -1.0 * (player.position - self.position).normalized()
		timer.start(base_fear_time + randf_range(-time_variation, time_variation))
		return true
		
	return false
	
func start_fear() -> void:
	velocity = direction * fear_speed
	$AnimatedSprite2D.play(&"run")
	move_and_slide()
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
	
	var player = self.get_tree().root.get_node("main/player")
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
