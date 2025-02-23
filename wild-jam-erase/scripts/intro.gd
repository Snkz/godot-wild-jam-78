extends CanvasLayer
signal restart()

# Called when the node enters the scene tree for the first time.
var original_radius = 0;
var gameintro_active = false
var gameintro_shuttingdown = false;
func _ready() -> void:
	gameintro_active = false
	
	var parent = self.get_parent()
	var player = self.get_node("../player")
	var foreground = self.get_node("../foreground")
	
	parent.connect("gamestart", _on_gamestart)
	original_radius = player.mask_radius
	foreground.get_child(0).material.set_shader_parameter("holeCenter", player.position)
	foreground.get_child(0).material.set_shader_parameter("holeRadius", 3000)
	

func _on_gamestart() -> void:
	var parent = self.get_parent()
	parent.camera_shake.emit(0.1, 0.25)

	var player = self.get_node("../player")
	player.mask_radius = 0
	
	gameintro_shuttingdown = false
	get_tree().paused = true
	visible = true
	
	var logo = get_node("logo")
	
	logo.play(&"default")
	await logo.animation_finished
	var tween = create_tween()
	tween.tween_property(logo, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	var background = get_node("background")
	background.visible = false
	logo.visible = false
	
	gameintro_active = true

	var instructions = get_node("instructions")
	var start = get_node("start")
	instructions.visible_ratio = 0
	start.visible_ratio = 0

	var instruction_tween = typewriter(instructions, 2.0)
	await instruction_tween.finished
	await get_tree().create_timer(0.25).timeout
	var start_tween = typewriter(start, 0.5)
	await start_tween.finished

	start.visible_ratio = 0
	blink(start, 7, 0.25)

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

		
func _unhandled_input(event):
	if not gameintro_active:
		return
	if event is InputEventMouse:
		if event.is_pressed():
			var parent = self.get_parent()
			parent.camera_shake.emit(0.2, 0.1)

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			gameintro_shuttingdown = true

			var player = self.get_node("../player")
			var foreground = self.get_node("../foreground")
			var creatures = get_node("creatures").get_children()
			
			var parent = self.get_parent()
			parent.camera_shake.emit(0.2, 0.2)
			
			var last_animation = null
			for creature in creatures:
				var animation = creature.get_node("AnimatedSprite2D")
				animation.play(&"dust")
				last_animation = animation
		
			#if  last_animation:
				#await last_animation.animation_finished  
			
			gameintro_active = false
			visible = false
			get_tree().paused = false
			
			player.mask_radius = 3000
			
			restart.emit()
		if event.pressed and not OS.get_name() == "Web" and event.keycode == KEY_ESCAPE:
			get_tree().quit()

func typewriter(node, duration) -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(node, "visible_ratio", 1.0, duration).from(0.0)
	return tween
	
func blink(node, loops, duration_ms) -> void:
	var alpha = 1.0
	while loops > 0:
		node.visible_ratio = alpha
		await get_tree().create_timer(duration_ms).timeout
		if alpha > 0.0: 
			alpha = 0.0
		else: 
			alpha = 1.0
		loops = loops - 1
