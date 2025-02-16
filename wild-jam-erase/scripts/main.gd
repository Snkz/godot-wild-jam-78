extends Node2D

@export var creature_scene: PackedScene
@export var grid_height: int
@export var grid_width: int
@export var playable_area_offset: Vector2

@export var num_green_creatures := 6
@export var green_noise_threshold := 0.05
@export var num_red_creatures := 8
@export var red_noise_threshold := 0.2
@export var num_blue_creatures := 14
@export var blue_noise_threshold := 0.55
@export var num_white_creatures := 4
@export var white_noise_threshold := 0.7
@export var num_yellow_creatures := 2
@export var yellow_noise_threshold := 1.0

var selected_creature: Creature
var rng = RandomNumberGenerator.new()
var creature_spawns = []
var matched_count = 0

signal gameover()

func _on_creature_deleted(node, index) -> void:
	var creatures = get_tree().get_nodes_in_group("creatures")
	var count = len(creatures)
	if count <= 0:
		gameover.emit()
		
func _on_restart() -> void:
	var creatures = get_tree().get_nodes_in_group("creatures")
	for creature in creatures:
		creature.queue_free()
	
	creature_spawns = []
	matched_count = 0
	generate_creatures()
	

func generate_grid() -> void:
	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var creature_picks = {"yellow": 0, "blue": 0, "green": 0, "red": 0, "white": 0}
	
	# Generate positions for all grid slots
	var index = 0
	for i in range(1, grid_width):
		for j in range(1, grid_height):
			var random_offset_scale = 5.0
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
		if abs(result) < green_noise_threshold and creature_picks.green < num_green_creatures:
			creature_colour = Color(0.0, 1.0, 0.0)
			creature_picks.green += 1
		elif abs(result) < red_noise_threshold and creature_picks.red < num_red_creatures:
			creature_colour = Color(1.0, 0.0, 0.0)
			creature_picks.red += 1
		elif abs(result) < blue_noise_threshold and creature_picks.blue < num_blue_creatures:
			creature_colour = Color(0.0, 0.0, 1.0)
			creature_picks.blue += 1
		elif abs(result) < white_noise_threshold and creature_picks.white < num_white_creatures:
			creature_colour = Color(1.0, 1.0, 1.0)
			creature_picks.white += 1
		elif abs(result) < yellow_noise_threshold and creature_picks.yellow < num_yellow_creatures:
			creature_colour = Color(1.0, 1.0, 0.0)
			creature_picks.yellow += 1
		# Now just fill in the spawns
		elif creature_picks.green < num_green_creatures:
			creature_colour = Color(0.0, 1.0, 0.0)
			creature_picks.green += 1
		elif red_noise_threshold and creature_picks.red < num_red_creatures:
			creature_colour = Color(1.0, 0.0, 0.0)
			creature_picks.red += 1
		elif blue_noise_threshold and creature_picks.blue < num_blue_creatures:
			creature_colour = Color(0.0, 0.0, 1.0)
			creature_picks.blue += 1
		elif white_noise_threshold and creature_picks.white < num_white_creatures:
			creature_colour = Color(0.0, 0.0, 0.0)
			creature_picks.white += 1
		elif yellow_noise_threshold and creature_picks.yellow < num_yellow_creatures:
			creature_colour = Color(1.0, 1.0, 0.0)
			creature_picks.yellow += 1

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
			
			var creature = creature_scene.instantiate()
			creature.name = "creature " + str(info.index)
			creature.index = info.index
			creature.position = info.position
			creature.modulate = info.colour
			info.node = creature

			# Spawn the creature by adding it to the Main scene.
			creature.add_to_group("creatures")
			var creatures = get_tree().get_nodes_in_group("creatures")
			for c in creatures: 
				c.connect("creature_deleted", _on_creature_deleted)

			var entity_layer = self.get_node("entity_layer")
			entity_layer.add_child(creature)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	var player = self.get_node("player")
	player.connect("creature_selected", _on_creature_selected)
	
	var gameover = self.get_node("gameover")
	gameover.connect("restart", _on_restart)
	generate_creatures()
			
func _process(delta):
	var window_rect = get_viewport().get_visible_rect()
	var mouse_pos = get_viewport().get_mouse_position()

	if window_rect.has_point(mouse_pos):
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_creature_info(index) -> Dictionary:
	for creature_spawn in creature_spawns:
		if creature_spawn.index == index:
			print("CREATURE FOUND: ", index, " ", creature_spawn)
			return creature_spawn
			
	return {index: null}

func _on_creature_selected(node, index):
	var node_info = get_creature_info(index)
	var selected_info = {}
	if selected_creature:
		selected_info = get_creature_info(selected_creature.index)
	
	if selected_creature == null:
		node.emit_signal("creature_matched", selected_creature, true, false)
		selected_creature = node
		print("NEW", index, node_info.colour)
	elif selected_creature.index == index:
		node.emit_signal("creature_matched", selected_creature, false, false)
		selected_creature = null
		print("SAME", index, node_info.colour)
	elif node_info.colour == selected_info.colour:
		node.emit_signal("creature_matched", selected_creature, true, true)
		selected_creature.emit_signal("creature_matched", selected_creature, true, true)
		selected_creature = null
		print("MATCH", index, node_info.colour, selected_info.index, selected_info.colour)
		matched_count = matched_count + 2
	elif node_info.colour != selected_info.colour:
		selected_creature.emit_signal("creature_matched", selected_creature, false, false)
		node.emit_signal("creature_matched", selected_creature, false, false)
		selected_creature = null
		print("NO MATCH", index, node_info.colour, " ", selected_info.colour)
	else:
		print("ERROR")
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
