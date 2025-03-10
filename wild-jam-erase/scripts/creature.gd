class_name Creature
extends CharacterBody2D

signal creature_highlighted(bool)
signal nearest_creature_highlighted(bool)
signal creature_matched(a, b, c, d)
signal creature_deleted(a, b)
signal creature_deselected(a, b)
signal creature_gameover()
signal creature_matchmade(node)
signal creature_won()

var index : int
var colour : Color
var layer : String

enum BehaviourState { IDLE, WANDER, CAUGHT, DUST, FEAR, CHASE, REVEAL, SELECTED, TELEPORT, MIMIC, WON }
var current_behaviour = BehaviourState.IDLE

@export var idle_base_time := 3.0
@export var time_variation := 1.0
@export var explode_on_click := false

@export_group("wander", "wander_")
@export var wander_speed := 30.0
@export var wander_chance := 0.3
@export var wander_base_time := 2.0

@export_group("chase", "chase_")
@export var chase_chance := 0.0
@export var chase_distance_min_threshold := 10
@export var chase_distance_max_threshold := 250
@export var chase_speed := 30.0
@export var chase_base_time := 1.0

@export_group("fear", "fear_")
@export var fear_chance := 0.0
@export var fear_speed := 30.0
@export var fear_distance_min_threshold := 50
@export var fear_distance_max_threshold := 200
@export var fear_base_time := 2.0

@export_group("reveal", "reveal_")
@export var reveal_colour_on_click := false
@export var reveal_base_time := 1.0

@export_group("teleport", "teleport_")
@export var teleport_chance := 0.0
@export var teleport_speed := 30.0
@export var teleport_should_travel := false
var teleport_target_position := Vector2.ZERO
var teleport_used = true
@export var teleport_distance_min_threshold := 50
@export var teleport_distance_max_threshold := 200
@export var teleport_base_time := 2.0

@export_group("mimic", "mimic_")
@export var mimic_chance := 0.0
@export var mimic_highlight_threshold := 3.0
var mimic_node = null
var mimic_active = false
var mimic_highlight_time = 0.0

var is_dying = false
var is_highlighted = false
var is_winner = false

var tween_hover: Tween
var direction := Vector2.ZERO
var timer = null

func _ready() -> void:
	randomize()
	timer = Timer.new()	
	timer.one_shot = true
	connect("creature_highlighted", _on_creature_highlighted)
	connect("nearest_creature_highlighted", _on_nearest_creature_highlighted)
	connect("creature_matched", _on_creature_matched)
	connect("creature_gameover", _on_creature_gameover)
	connect("creature_won", _on_creature_won)


	var offset : float = randf_range(0, $AnimatedSprite2D.sprite_frames.get_frame_count($AnimatedSprite2D.animation))
	$AnimatedSprite2D.set_frame_and_progress(offset, offset)
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)
	
	$AnimatedSprite2D.play_backwards(&"dust")

	add_child(timer)
	timer.timeout.connect(_on_timeout)

func _on_creature_highlighted(state) -> void:
	is_highlighted = state
	
	if current_behaviour == BehaviourState.WON:
		return
		
	if current_behaviour == BehaviourState.DUST:
		return
		
	if current_behaviour == BehaviourState.SELECTED:
		return
		
	if current_behaviour == BehaviourState.REVEAL:
		return
		
	if current_behaviour == BehaviourState.MIMIC:
		return
	
	if state and (current_behaviour == BehaviourState.WANDER or current_behaviour == BehaviourState.IDLE): 
		current_behaviour = BehaviourState.CAUGHT
		$AnimatedSprite2D.play(&"caught")

func _on_animation_finished() -> void:
	var main = self.get_tree().root.get_node("main")
	if not main.game_started:
		return
			
	if ($AnimatedSprite2D.animation == &"caught"):
		if current_behaviour == BehaviourState.CAUGHT:
			var result = init_teleport() or init_chase() or init_fear() or init_wander()
			if not result:
				start_idle()
				
	if ($AnimatedSprite2D.animation == &"dust"):
		if current_behaviour == BehaviourState.TELEPORT:
			if not teleport_used:
				start_instant_teleport()
			else:
				$AnimatedSprite2D.play(&"caught")
		else:
			start_idle()
				
	if current_behaviour == BehaviourState.MIMIC:
		if ($AnimatedSprite2D.animation == &"mimic"):
			if (mimic_active):
				start_instant_mimic()
			else:
				start_instant_mimic_fail_free()
		elif ($AnimatedSprite2D.animation == &"mimic_caught"):
			start_instant_mimic_fail()
		elif ($AnimatedSprite2D.animation == &"mimic_dust"):
			if (mimic_active):
				$AnimatedSprite2D.play(&"mimic_idle")
			else:
				$AnimatedSprite2D.play_backwards(&"mimic")



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
		
func _on_creature_matched(node, selected, matched, count) -> void:
	$AnimatedSprite2D.material.set_shader_parameter("line_thickness", 0)
	
	if selected:
		# Clear states here before changing what happens, avoid else block to allow visible deaths
		clear_selected()
		clear_reveal()
		
		var player = self.get_tree().root.get_node("main/player")
		var audio = player.get_node("audio_hit")
		audio.play()
		move_selected()
		if reveal_colour_on_click and count == 1:
			start_reveal()
			$AnimatedSprite2D.play(&"selected")
			current_behaviour = BehaviourState.REVEAL
		elif explode_on_click:
			creature_matchmade.emit(self)
			creature_deselected.emit(self, index)
			start_dust()
		else:
			current_behaviour = BehaviourState.SELECTED
			$AnimatedSprite2D.play(&"selected")
	else:
		if current_behaviour == BehaviourState.SELECTED or current_behaviour == BehaviourState.REVEAL:
			if matched:
				creature_matchmade.emit(self)
				move_selected()
				start_dust()
			else:
				$AnimatedSprite2D.play(&"caught")
				current_behaviour = BehaviourState.CAUGHT
				clear_selected()
				clear_reveal()

func start_reveal() -> void:
	var selected = get_tree().root.get_node("main/selected")	
	var creatures = get_tree().root.get_node("main/creatures/ysort")	
	var colour_node = creatures.get_node(layer)
	
	if colour_node:
		creatures.remove_child(colour_node)
		selected.add_child(colour_node)
		
	timer.start(reveal_base_time)
	

func clear_reveal() -> void:
	var selected = get_tree().root.get_node("main/selected")	
	var creatures = get_tree().root.get_node("main/creatures/ysort")	

	var colour_node = selected.get_node(layer)
	if colour_node:
		selected.remove_child(colour_node)
		creatures.add_child(colour_node)

func move_selected() -> void:
	var selected = get_tree().root.get_node("main/selected")	
	var creatures = get_tree().root.get_node("main/creatures/ysort")	

	var creature_colour = creatures.get_node(layer)
	var creature_node = null
	if creature_colour:
		creature_node = creature_colour.get_node(str(name))
	
	if creature_node:
		var colour_node = selected.get_node(layer)
		if not colour_node:
			colour_node = creatures.get_node(layer)	
			
		assert(colour_node)
		colour_node.remove_child(creature_node)
		selected.add_child(creature_node)

func clear_selected() -> void: 
	var selected = get_tree().root.get_node("main/selected")	
	var creatures = get_tree().root.get_node("main/creatures/ysort")	

	var creature_node = selected.get_node(str(name))
	if creature_node:
		var colour_node = selected.get_node(layer)
		if not colour_node:
			colour_node = creatures.get_node(layer)	
		assert(colour_node)
		selected.remove_child(creature_node)
		colour_node.add_child(creature_node)

func _on_timeout() -> void:
	if current_behaviour == BehaviourState.WON:
		return

	if current_behaviour == BehaviourState.DUST:
		return
		
	if current_behaviour == BehaviourState.SELECTED:
		return
		
	if current_behaviour == BehaviourState.MIMIC:
		return
		
	if current_behaviour == BehaviourState.REVEAL:
		clear_reveal()
		return
	
	var result = init_mimic() or init_teleport() or init_chase() or init_fear() or init_wander()
	if not result:
		start_idle()

func _on_creature_gameover() -> void:
	if is_winner:
		return
	start_dust()

func _on_creature_won() -> void:
	is_winner = true
	start_reveal()
	current_behaviour = BehaviourState.WON
	$AnimatedSprite2D.play(&"caught")
	
	
func start_idle() -> void:	
	current_behaviour = BehaviourState.IDLE
	$AnimatedSprite2D.play(&"idle")
	direction = Vector2.ZERO
	timer.start(idle_base_time + randf_range(-time_variation, time_variation))

func start_dust() -> void:
	if is_dying:
		return
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
		
		timer.start(wander_base_time + randf_range(-time_variation, time_variation))
		$AnimatedSprite2D.play(&"run")
		return true
	
	return false
	
func start_wander() -> void:
	velocity = direction * wander_speed
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
		timer.start(chase_base_time)
		$AnimatedSprite2D.play(&"run")
		return true
		
	return false
	
func start_chase() -> void:
	var player = self.get_tree().root.get_node("main/player")
	direction = (player.position - self.position).normalized()
	var distance = player.position.distance_to(self.position)
	if distance < chase_distance_min_threshold or distance >= chase_distance_max_threshold + 10.0:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		current_behaviour = BehaviourState.CAUGHT
		$AnimatedSprite2D.play(&"caught")
	
	velocity = direction * chase_speed
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true

		
func init_fear() -> bool:
	if current_behaviour != BehaviourState.IDLE and current_behaviour != BehaviourState.WANDER:
		return false
	
	var player = self.get_tree().root.get_node("main/player")
	var distance = player.position.distance_to(self.position)
	if distance > fear_distance_min_threshold and distance < fear_distance_max_threshold and randf() < fear_chance:
		current_behaviour = BehaviourState.FEAR
		direction = -1.0 * (player.position - self.position).normalized()
		timer.start(fear_base_time)
		$AnimatedSprite2D.play(&"run")

		return true
		
	return false
	
func start_fear() -> void:
	var player = self.get_tree().root.get_node("main/player")
	direction = -1.0 * (player.position - self.position).normalized()
	velocity = direction * fear_speed
	
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = false
	else:
		$AnimatedSprite2D.flip_h = true
	
	var distance = player.position.distance_to(self.position)
	if distance < fear_distance_min_threshold or distance >= fear_distance_max_threshold:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		current_behaviour = BehaviourState.CAUGHT
		$AnimatedSprite2D.play(&"caught")
		

func init_teleport() -> bool:
	if current_behaviour != BehaviourState.IDLE and current_behaviour != BehaviourState.WANDER:
		return false
	
	var player = self.get_tree().root.get_node("main/player")
	var distance = player.position.distance_to(self.position)
	if distance > teleport_distance_min_threshold and distance < teleport_distance_max_threshold and randf() < teleport_chance:
		current_behaviour = BehaviourState.TELEPORT
		var screen_res = Vector2()
		screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
		screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
		var edge_buffer = Vector2(80, 60)
		teleport_target_position = Vector2(randf_range(edge_buffer.x, screen_res.x - edge_buffer.y), 
			randf_range(edge_buffer.y, screen_res.y - edge_buffer.y))
		
		if teleport_should_travel:
			direction = -1.0 * (teleport_target_position - self.position).normalized()
			$AnimatedSprite2D.play(&"run")
		else:
			$AnimatedSprite2D.play(&"dust")
		
		teleport_used = false
		timer.start(teleport_base_time)
		return true
		
	return false

func init_mimic() -> bool:
	if current_behaviour != BehaviourState.IDLE and current_behaviour != BehaviourState.WANDER:
		return false
	
	var player = self.get_tree().root.get_node("main/player")
	var main = self.get_tree().root.get_node("main")
	if (main.active_selection.size() >= 1 and not is_highlighted) and randf() < mimic_chance:
		current_behaviour = BehaviourState.MIMIC
		mimic_node = main.active_selection.back()
		mimic_active = true
		mimic_highlight_time = mimic_highlight_threshold
	
		# Copy over animation info
		var animation = mimic_node.get_node("AnimatedSprite2D")
		$AnimatedSprite2D.sprite_frames.clear(&"mimic_dust")
		$AnimatedSprite2D.sprite_frames.set_animation_loop(&"mimic_dust", animation.sprite_frames.get_animation_loop(&"dust"))
		$AnimatedSprite2D.sprite_frames.set_animation_speed(&"mimic_dust", animation.sprite_frames.get_animation_speed(&"idle"))
		for i in range(animation.sprite_frames.get_frame_count(&"dust")):
			var frame = animation.sprite_frames.get_frame_texture(&"dust", i)	
			var duration = animation.sprite_frames.get_frame_duration(&"dust", i)	
			$AnimatedSprite2D.sprite_frames.add_frame(&"mimic_dust", frame, duration, i)

		$AnimatedSprite2D.sprite_frames.clear(&"mimic_idle")
		$AnimatedSprite2D.sprite_frames.set_animation_loop(&"mimic_idle", animation.sprite_frames.get_animation_loop(&"idle"))
		$AnimatedSprite2D.sprite_frames.set_animation_speed(&"mimic_idle", animation.sprite_frames.get_animation_speed(&"idle"))
		for i in range(animation.sprite_frames.get_frame_count(&"idle")):
			var frame = animation.sprite_frames.get_frame_texture(&"idle", i)	
			var duration = animation.sprite_frames.get_frame_duration(&"idle", i)	
			$AnimatedSprite2D.sprite_frames.add_frame(&"mimic_idle", frame, duration, i)
		
		$AnimatedSprite2D.sprite_frames.clear(&"mimic_caught")
		$AnimatedSprite2D.sprite_frames.set_animation_loop(&"mimic_caught", animation.sprite_frames.get_animation_loop(&"caught"))
		$AnimatedSprite2D.sprite_frames.set_animation_speed(&"mimic_caught", animation.sprite_frames.get_animation_speed(&"caught"))
		for i in range(animation.sprite_frames.get_frame_count(&"caught")):
			var frame = animation.sprite_frames.get_frame_texture(&"caught", i)	
			var duration = animation.sprite_frames.get_frame_duration(&"caught", i)	
			$AnimatedSprite2D.sprite_frames.add_frame(&"mimic_caught", frame, duration, i)

		$AnimatedSprite2D.play(&"mimic")
		return true
		
	return false
	
func start_mimic(delta) -> bool:
	var player = self.get_tree().root.get_node("main/player")
	var main = self.get_tree().root.get_node("main")
	var distance = player.position.distance_to(self.position)
	
	if is_highlighted:
		mimic_highlight_time -= delta
	else:
		mimic_highlight_time = mimic_highlight_threshold
		
	if mimic_active and (main.active_selection.size() == 0 or mimic_highlight_time < 0):
		mimic_active = false
		$AnimatedSprite2D.play(&"mimic_caught")
		return false
	
	return true
	
func start_instant_mimic() -> void:
	assert(mimic_node)
	$AnimatedSprite2D.play_backwards(&"mimic_dust")


func start_instant_mimic_fail() -> void:
	assert(mimic_node)		
	mimic_node = null

	$AnimatedSprite2D.play(&"mimic_dust")

func start_instant_mimic_fail_free() -> void:
	assert(not mimic_node)
	current_behaviour = BehaviourState.CAUGHT
	$AnimatedSprite2D.play(&"caught")

func start_teleport() -> void:
	var player = self.get_tree().root.get_node("main/player")
	
	# We handle the instant teleport at the end of animation
	if teleport_should_travel:
		direction = 1.0 * (teleport_target_position - self.position).normalized()
		velocity = direction * teleport_speed
		if direction.x < 0:
			$AnimatedSprite2D.flip_h = false
		else:
			$AnimatedSprite2D.flip_h = true
	
		var distance = teleport_target_position.distance_to(self.position)
		if distance < teleport_distance_min_threshold:
			direction = Vector2.ZERO
			velocity = Vector2.ZERO
			current_behaviour = BehaviourState.CAUGHT
			$AnimatedSprite2D.play(&"caught")

func start_instant_teleport() -> void:
	if not teleport_should_travel:
		position = teleport_target_position
		teleport_used = true;
		$AnimatedSprite2D.play_backwards(&"dust")

func _physics_process(delta: float) -> void:
	if current_behaviour == BehaviourState.WANDER:
		start_wander()
	elif current_behaviour == BehaviourState.CHASE:
		start_chase()
	elif current_behaviour == BehaviourState.FEAR:
		start_fear()
	elif current_behaviour == BehaviourState.TELEPORT:
		start_teleport()
	elif current_behaviour == BehaviourState.MIMIC:
		start_mimic(delta)
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	if is_highlighted and current_behaviour == BehaviourState.IDLE:
		init_teleport() or init_chase() or init_fear()
		
	if current_behaviour == BehaviourState.IDLE or current_behaviour == BehaviourState.WANDER:
		init_mimic()
