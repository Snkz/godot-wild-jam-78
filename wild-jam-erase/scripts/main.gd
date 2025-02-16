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
			index = index + 1
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
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	var max_excluded = 16
	var exclusion_threshold = 0.35
	
	generate_grid()
	
	var index = 0
	for i in range(1, grid_width):
		for j in range(1, grid_height):
			var creature = creature_scene.instantiate()
			var info = creature_spawns[index];
			if info.colour == null:
				continue
				
			creature.name = "creature " + str(index)
			creature.index = index
			creature.position = info.position
			creature.modulate = info.colour

			index = index + 1

			# Spawn the creature by adding it to the Main scene.
			creature.add_to_group("creatures")
			var player = self.get_node("player")
			player.connect("creature_selected", _on_creature_selected)

			var entity_layer = self.get_node("entity_layer")
			entity_layer.add_child(creature)
			var creatures = get_tree().get_nodes_in_group("creatures")
			for c in creatures: 
				c.connect("creature_selected", _on_creature_selected)

func _process(delta):
	var window_rect = get_viewport().get_visible_rect()
	var mouse_pos = get_viewport().get_mouse_position()

	if window_rect.has_point(mouse_pos):
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_creature_selected(node, index):
	if node == selected_creature:
		selected_creature = null
		node._start_dust()
	else:
		selected_creature = node
	
func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
