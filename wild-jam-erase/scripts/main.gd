extends Node2D

@export var creature_scene: PackedScene
@export var grid_height: int
@export var grid_width: int
@export var playable_area_offset: Vector2

var selected_creature: Creature
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_res = Vector2()
	screen_res.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	screen_res.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	var max_excluded = 16
	var exclusion_threshold = 0.35
	
	for i in range(1, grid_width):
		for j in range(1, grid_height):
			var excluded_threshold = rng.randf_range(0, 1.0)
			if max_excluded > 0 and excluded_threshold < exclusion_threshold:
				max_excluded = max_excluded -1;
				continue
				
			var creature = creature_scene.instantiate()
			var random_offset_scale = 5.0
			
			var random_offset_x = rng.randf_range(-screen_res.x / grid_width / random_offset_scale, 
				screen_res.x / grid_width / random_offset_scale)
			var random_offset_y = rng.randf_range(-screen_res.y / grid_height / random_offset_scale, 
				screen_res.y / grid_height / random_offset_scale)

			creature.position = Vector2(i * screen_res.x / grid_width + playable_area_offset.x + random_offset_x,
			 j * screen_res.y / grid_height + playable_area_offset.y + random_offset_y)
			creature.name = "creature " + str(i) + ":" + str(j)
			creature.index = Vector2(i, j)

			# Spawn the creature by adding it to the Main scene.
			creature.add_to_group("creatures")
			var player = self.get_node("player")
			player.connect("creature_selected", _on_creature_selected)

			var entity_layer = self.get_node("entity_layer")
			entity_layer.add_child(creature)
			#var creatures = get_tree().get_nodes_in_group("creatures")
			#for c in creatures: 
				#c.connect("creature_selected", _on_creature_selected)

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
