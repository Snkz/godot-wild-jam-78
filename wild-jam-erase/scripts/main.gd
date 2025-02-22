extends Camera2D

@export var grid_height: int
@export var grid_width: int
@export var playable_area_offset: Vector2
@export var max_camera_shake_offset = Vector2(100, 75) 
@export var max_camera_roll = 0.1 
@export var respawn_rate := 30.0
@export var respawn_cap := 1
@export var respawn_as_mimic_chance := 0.5

@export_group("green", "green_")
@export var green_num_creatures := 6
@export var green_noise_threshold := 0.05
@export var green_creature_scene: PackedScene

@export_group("red", "red_")
@export var red_num_creatures := 8
@export var red_noise_threshold := 0.2
@export var red_creature_scene: PackedScene

@export_group("blue", "blue_")
@export var blue_num_creatures := 14
@export var blue_noise_threshold := 0.55
@export var blue_creature_scene: PackedScene

@export_group("white", "white_")
@export var white_num_creatures := 4
@export var white_noise_threshold := 0.7
@export var white_creature_scene: PackedScene

@export_group("yellow", "yellow_")
@export var yellow_num_creatures := 2
@export var yellow_noise_threshold := 1.0
@export var yellow_creature_scene: PackedScene

var rng = RandomNumberGenerator.new()
var creature_picks = {}
var creature_spawns = []
var active_selection = []
var matched_count = 0
var game_time = 0.0
var respawn_time = respawn_rate
var noise = null
var camera_shake_lifetime = 0
var camera_shake_strength = 0
var creatures_generated = false
var game_started = false

signal gameover(int, float)
signal gamestart()
signal camera_shake(a, b)

func _on_creature_deleted(node, index) -> void:	
	camera_shake.emit(0.2, 0.1)
	node.is_dying = true
	var player = self.get_node("player")
	var audio = player.get_node("audio_dust")
	audio.play()
	
	creature_picks[node.layer] -= 1
	assert(creature_picks[node.layer] >=0)

	var creatures = get_tree().get_nodes_in_group("creatures")
	var count = 0
	for creature in creatures:
		if not creature.is_dying:
			count += 1
			
	if count <= 0:
		gameover.emit(matched_count, game_time)
		
func _on_restart() -> void:
	game_started = true
	var creatures = get_tree().get_nodes_in_group("creatures")
	for creature in creatures:
		creature.queue_free()
		
	# Saftey net, restore groups
	var selected = get_tree().root.get_node("main/selected")	
	var creature_layer = get_tree().root.get_node("main/creatures/ysort")	
	for layer in creature_picks:
		var colour_node = selected.get_node(layer)
		if colour_node:
			selected.remove_child(colour_node)
			creature_layer.add_child(colour_node)
	
	creature_spawns = []
	active_selection = []
	matched_count = 0
	game_time = 0.0
	camera_shake_lifetime = 0
	creatures_generated = false
	respawn_time = respawn_rate
	offset = Vector2(0.0, 0.0)
	rotation = 0.0
	generate_creatures()
	
func do_camera_shake(strength, seed) -> void:
	var amount = pow(strength, 2)
	rotation = max_camera_roll * amount * randf_range(-1.0, 1.0)
	offset.x = max_camera_shake_offset.x * amount * randf_range(-1.0, 1.0)
	offset.y = max_camera_shake_offset.y * amount * randf_range(-1.0, 1.0)

func _on_camera_shake(strength, lifetime) -> void:
	noise.seed = randi()
	camera_shake_lifetime = max(camera_shake_lifetime, lifetime)
	camera_shake_strength = max(camera_shake_strength, strength)
	
func _on_gameover(score, time) -> void:
	#camera_shake.emit(0.5, 0.25)
	pass

func _on_matchmade() -> void:
	matched_count += 1 * active_selection.size() # combos scale score

func generate_grid() -> void:
	noise.seed = randi()
	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	creature_picks = {"yellow": 0, "blue": 0, "green": 0, "red": 0, "white": 0}
	
	# Generate positions for all grid slots
	var index = 0
	for i in range(1, grid_width):
		for j in range(1, grid_height):
			var random_offset_scale = 3.0
			var random_offset_x = rng.randf_range(-screen_res.x / grid_width / random_offset_scale, 
				screen_res.x / grid_width / random_offset_scale)
			var random_offset_y = rng.randf_range(-screen_res.y / grid_height / random_offset_scale, 
				screen_res.y / grid_height / random_offset_scale)
			var position = Vector2(i * screen_res.x / grid_width + playable_area_offset.x + random_offset_x,
			 j * screen_res.y / grid_height + playable_area_offset.y + random_offset_y)
	
			var result = noise.get_noise_2d(position.x, position.y)
			var creature_colour = null
			creature_spawns.push_back({"position" : position, "noise" : result, "colour": creature_colour, "index" : index})
			index = index + 1

	# Randomly spawn monsters
	creature_spawns.shuffle()
	for creature_spawn in creature_spawns:
		var result = creature_spawn.noise
		var creature_colour = null
		if abs(result) < green_noise_threshold and creature_picks.green < green_num_creatures:
			creature_colour = Color(0.0, 1.0, 0.0)
			creature_picks.green += 1
			creature_spawn.creature_scene = green_creature_scene
			creature_spawn.layer = "green"
		elif abs(result) < red_noise_threshold and creature_picks.red < red_num_creatures:
			creature_colour = Color(1.0, 0.0, 0.0)
			creature_picks.red += 1
			creature_spawn.creature_scene = red_creature_scene
			creature_spawn.layer = "red"

		elif abs(result) < blue_noise_threshold and creature_picks.blue < blue_num_creatures:
			creature_colour = Color(0.0, 0.0, 1.0)
			creature_picks.blue += 1
			creature_spawn.creature_scene = blue_creature_scene
			creature_spawn.layer = "blue"

		elif abs(result) < white_noise_threshold and creature_picks.white < white_num_creatures:
			creature_colour = Color(1.0, 1.0, 1.0)
			creature_picks.white += 1
			creature_spawn.creature_scene = white_creature_scene
			creature_spawn.layer = "white"

		elif abs(result) < yellow_noise_threshold and creature_picks.yellow < yellow_num_creatures:
			creature_colour = Color(1.0, 1.0, 0.0)
			creature_picks.yellow += 1
			creature_spawn.creature_scene = yellow_creature_scene
			creature_spawn.layer = "yellow"

		# Now just fill in the spawns
		elif creature_picks.green < green_num_creatures:
			creature_colour = Color(0.0, 1.0, 0.0)
			creature_picks.green += 1
			creature_spawn.creature_scene = green_creature_scene
			creature_spawn.layer = "green"

		elif red_noise_threshold and creature_picks.red < red_num_creatures:
			creature_colour = Color(1.0, 0.0, 0.0)
			creature_picks.red += 1
			creature_spawn.creature_scene = red_creature_scene
			creature_spawn.layer = "red"

		elif blue_noise_threshold and creature_picks.blue < blue_num_creatures:
			creature_colour = Color(0.0, 0.0, 1.0)
			creature_picks.blue += 1
			creature_spawn.creature_scene = blue_creature_scene
			creature_spawn.layer = "blue"

		elif white_noise_threshold and creature_picks.white < white_num_creatures:
			creature_colour = Color(0.0, 0.0, 0.0)
			creature_picks.white += 1
			creature_spawn.creature_scene = white_creature_scene
			creature_spawn.layer = "white"

		elif yellow_noise_threshold and creature_picks.yellow < yellow_num_creatures:
			creature_colour = Color(1.0, 1.0, 0.0)
			creature_picks.yellow += 1
			creature_spawn.creature_scene = yellow_creature_scene
			creature_spawn.layer = "yellow"


		creature_spawn.colour = creature_colour
	
	print(creature_picks)
	
func generate_creatures() -> void:
	generate_grid()
	
	var index = 0
	for i in range(1, grid_width):
		for j in range(1, grid_height):
			var info = creature_spawns[index];
			index = index + 1
			if info.colour == null:
				continue
			
			var creature = info.creature_scene.instantiate()
			creature.name = "creature " + str(info.index)
			creature.index = info.index
			creature.position = info.position
			creature.colour = info.colour
			creature.layer = info.layer
			info.node = creature

			# Spawn the creature by adding it to the Main scene.
			creature.add_to_group("creatures")

			var group = self.get_node("creatures/ysort/" + info.layer)
			group.add_child(creature)

	var creatures = get_tree().get_nodes_in_group("creatures")
	for c in creatures: 
		c.connect("creature_deleted", _on_creature_deleted)
		c.connect("creature_deselected", _on_creature_deselected)
		c.connect("creature_matchmade", _on_matchmade)
		
	creatures_generated = true

func respawn_creatures() -> void:	
	var index = 0
	var respawn_count = respawn_cap
	var spawned_mimic = false
	creature_spawns.shuffle()
	for info in creature_spawns:
		if respawn_count <= 0:
			break
		if info.colour and info.node and not is_instance_valid(info.node):
			var group = self.get_node("creatures/ysort/" + info.layer)
			if not group:
				continue
				
			if creature_picks[info.layer] == 0:
				continue

			# TODO: Adjust colour, currently we just hardcoding yellow
			# Check if should turn this creature into mimic, its okay if we turn the mimic into a mimic also
			if creature_picks[info.layer] > 1 and creature_picks[info.layer] % 2 == 0 and not spawned_mimic:
				if randf() < respawn_as_mimic_chance:
					info.colour = Color(1.0, 1.0, 0.0)
					info.creature_scene = yellow_creature_scene
					info.layer = "yellow"
					spawned_mimic = true

			var creature = info.creature_scene.instantiate()
			creature.name = "creature " + str(info.index)
			creature.index = info.index
			creature.position = info.position
			creature.colour = info.colour
			creature.layer = info.layer
			info.node = creature
			creature_picks[info.layer] += 1

			# Spawn the creature by adding it to the Main scene.
			creature.add_to_group("creatures")
			group.add_child(creature)
			creature.connect("creature_deleted", _on_creature_deleted)
			creature.connect("creature_deselected", _on_creature_deselected)
			respawn_count -= 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	var player = self.get_node("player")
	player.connect("creature_selected", _on_creature_selected)

	connect("camera_shake", _on_camera_shake)
	connect("gameover", _on_gameover)
	
	var gameover = self.get_node("gameover")
	gameover.connect("restart", _on_restart)
	var intro = self.get_node("intro")
	intro.connect("restart", _on_restart)
	
	gamestart.emit()
			
func _process(delta):
	var window_rect = get_viewport().get_visible_rect()
	var mouse_pos = get_viewport().get_mouse_position()
	game_time = game_time + delta
	
	if creatures_generated:
		respawn_time -= delta
		if respawn_time < 0.0:
			respawn_time = respawn_rate
			respawn_creatures()
	
	if camera_shake_lifetime > 0:
		do_camera_shake(camera_shake_strength, noise.seed)
		camera_shake_lifetime -= delta
	else:
		camera_shake_strength = 0;
		camera_shake_lifetime = 0;
		offset = Vector2(0.0, 0.0)
		rotation = 0.0


	if window_rect.has_point(mouse_pos):
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var audio = get_node("audio_background")
	var should_play = game_started or game_time > 0.6
	if should_play and not audio.is_playing():
		audio.play()


func get_creature_info(index) -> Dictionary:
	for creature_spawn in creature_spawns:
		if creature_spawn.index == index:
			return creature_spawn
			
	return {index: null}
	
	
# Do not call this while iterating, only exploding clicks should use
func _on_creature_deselected(node, index) -> void:
	active_selection.erase(node)
	
func _on_creature_selected(node, index) -> void:
	var node_info = get_creature_info(index)	
	if node and node.is_dying:
		return
	 
	# We clicked empty space
	if not node:
		for active in active_selection:
			active.emit_signal("creature_matched", active, false, len(active_selection) > 1, len(active_selection))
	
		active_selection.clear()
		return

	var selected_creature = active_selection.back()
	if not active_selection.has(node):
		active_selection.push_back(node)
	
	var selected_info = {}
	if is_instance_valid(selected_creature):
		selected_info = get_creature_info(selected_creature.index)

	# First selection click
	if len(active_selection) == 1 and is_instance_valid(node):
		node.emit_signal("creature_matched", node, true, false, len(active_selection))
	else:		
		# We clicked the same guy twice
		if selected_creature.index == index or active_selection.find(node) < active_selection.size() - 1:
			for active in active_selection:
				active.emit_signal("creature_matched", active, false, len(active_selection) > 1, len(active_selection))
			active_selection.clear()
		
		# New guy of our type was selected
		elif node_info.colour == selected_info.colour:
			node.emit_signal("creature_matched", selected_creature, true, true, len(active_selection))
		# Picked a guy that doesnt match our type
		elif node_info.colour != selected_info.colour:
			for active in active_selection:
				active.emit_signal("creature_matched", active, false, false, len(active_selection))
			
			active_selection.clear()
			node.emit_signal("creature_won")
			gameover.emit(matched_count, game_time)

func _unhandled_input(event):
	if OS.get_name() == "Web":
		return
		
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
