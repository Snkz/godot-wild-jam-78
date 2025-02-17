extends CanvasLayer
signal restart()

# Called when the node enters the scene tree for the first time.
var original_radius = 0;
var gameintro_active = false
var gameintro_shuttingdown = false;
func _ready() -> void:
	gameintro_active = false
	var parent = self.get_parent()
	parent.connect("gamestart", _on_gamestart)
	var player = self.get_node("../player")
	original_radius = player.mask_radius

func _on_gamestart() -> void:
	var player = self.get_node("../player")
	player.mask_radius = 0
	gameintro_active = true
	gameintro_shuttingdown = false
	get_tree().paused = true
	visible = true
	
	var audio = self.get_node("audio_gamestart")
	audio.play()

	var creatures = get_node("creatures").get_children()
	for creature in creatures:
		var animation = creature.get_node("AnimatedSprite2D")
		animation.play(&"caught")
		await animation.animation_finished 
	
func _process(delta: float) -> void:
	if not gameintro_active:
		return
		
	var player = self.get_node("../player")
	var foreground = self.get_node("../foreground")

	var increased_radius = 3000
	var lerp_speed = 1.0

	if not gameintro_shuttingdown:
		player.mask_radius = lerp(player.mask_radius, original_radius + increased_radius, lerp_speed * delta)
		foreground.get_child(0).material.set_shader_parameter("holeCenter", player.position)
		foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)
	else:
		lerp_speed = 10
		player.mask_radius = lerp(player.mask_radius, original_radius, lerp_speed * delta)
		foreground.get_child(0).material.set_shader_parameter("holeCenter", get_viewport().get_mouse_position())
		foreground.get_child(0).material.set_shader_parameter("holeRadius", player.mask_radius)
		
func _unhandled_input(event):
	if not gameintro_active:
		return
		
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			gameintro_shuttingdown = true

			var player = self.get_node("../player")
			var foreground = self.get_node("../foreground")
			var creatures = get_node("creatures").get_children()
			
			var audio = self.get_node("audio_restart")
			audio.play()
			
			var last_animation = null
			for creature in creatures:
				var animation = creature.get_node("AnimatedSprite2D")
				animation.play(&"dust")
				last_animation = animation
		
			if  last_animation:
				await last_animation.animation_finished  
			
			gameintro_active = false
			visible = false
			player.mask_radius = original_radius
			get_tree().paused = false
			
			restart.emit()
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
