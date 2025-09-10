extends Node2D

const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"

func _ready():
	# Set up dynamic positioning for all game elements
	setup_dynamic_positioning()
	
	# Load settings from config file and apply proper volumes
	load_and_apply_settings()
	
	# Load custom control bindings
	load_custom_controls()
	
	# Enable looping for background music using finished signal
	$"BackgroundMusic".finished.connect(_on_background_music_finished)
	
	# Play background sound
	$"BackgroundMusic".play()
	
	# Make sure the back button is visible
	$CanvasLayer/BackToMenuButton.visible = true
	
	# Connect to window resize signal for dynamic repositioning
	get_viewport().size_changed.connect(_on_window_resized)

func _on_window_resized():
	"""Handle window resize by repositioning all elements"""
	setup_dynamic_positioning()

func setup_dynamic_positioning():
	"""Set up all game elements to scale with window size"""
	var viewport = get_viewport()
	var screen_size = viewport.get_visible_rect().size
	var screen_center_x = screen_size.x / 2
	var screen_center_y = screen_size.y / 2
	
	# Player positioning
	var player_x_offset = screen_size.x * 0.15  # 15% from edges
	$"Player 1".position = Vector2(player_x_offset, screen_center_y)
	$"Player 2".position = Vector2(screen_size.x - player_x_offset, screen_center_y)
	
	# Background sprite positioning and scaling
	$Sprite2D.position = Vector2(screen_center_x, screen_center_y)
	# Scale background to fit screen
	var background_scale_x = screen_size.x / $Sprite2D.texture.get_width()
	var background_scale_y = screen_size.y / $Sprite2D.texture.get_height()
	$Sprite2D.scale = Vector2(background_scale_x, background_scale_y)
	
	# Ball positioning
	$Ball.position = Vector2(screen_center_x, screen_center_y)
	
	# Border positioning (walls and ceiling/floor)
	var border_thickness = 28
	var border_length = screen_size.y + 40  # Extra height for safety
	var wall_length = screen_size.x + 40   # Extra width for safety
	
	# Update border positions
	$Borders.position = Vector2(0, 0)  # Reset border container position
	
	# Right wall
	$Borders/CollisionShape2D.position = Vector2(screen_size.x + border_thickness/2, screen_center_y)
	$Borders/CollisionShape2D.shape.size = Vector2(border_thickness, border_length)
	
	# Left wall
	$Borders/CollisionShape2D2.position = Vector2(-border_thickness/2, screen_center_y)
	$Borders/CollisionShape2D2.shape.size = Vector2(border_thickness, border_length)
	
	# Top wall
	$Borders/CollisionShape2D3.position = Vector2(screen_center_x, -20)
	$Borders/CollisionShape2D3.shape.size = Vector2(wall_length, 20)
	
	# Bottom wall
	$Borders/CollisionShape2D4.position = Vector2(screen_center_x, screen_size.y + 20)
	$Borders/CollisionShape2D4.shape.size = Vector2(wall_length, 20)
	
	# Goal areas - positioned 20px before window borders
	var goal_width = 4
	var goal_height = screen_size.y + 40
	var goal_offset = 5  # 20px before window border
	
	# Left goal (Player 1 side) - 20px before left border
	$"Goal area player 1 side/Goal area at player 1".position = Vector2(goal_offset, screen_center_y)
	$"Goal area player 1 side/Goal area at player 1".shape.size = Vector2(goal_width, goal_height)
	
	# Right goal (Player 2 side) - 20px before right border
	$"Goal area player 2 side/Goal area at player 2".position = Vector2(screen_size.x - goal_offset, screen_center_y)
	$"Goal area player 2 side/Goal area at player 2"	.shape.size = Vector2(goal_width, goal_height)

func load_custom_controls():
	"""Load and apply custom control bindings from config file"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Default key bindings
		var default_bindings = {
			"Up__player1": KEY_W,
			"Down__player1": KEY_S,
			"Left__player1": KEY_A,
			"Right__player1": KEY_D,
			"Rotate_anticlockwise__player1": KEY_Q,
			"Rotate_clockwise__player1": KEY_E,
			"Up_player2": KEY_KP_8,
			"Down_player2": KEY_KP_2,
			"Left_player2": KEY_KP_4,
			"Right_player2": KEY_KP_6,
			"Rotate_anticlockwise__player2": KEY_KP_7,
			"Rotate_clockwise__player2": KEY_KP_9
		}
		
		# Apply custom bindings
		for action in default_bindings:
			var custom_key = config.get_value("controls", action, default_bindings[action])
			
			# Clear existing events for this action
			if InputMap.has_action(action):
				InputMap.action_erase_events(action)
			else:
				InputMap.add_action(action)
			
			# Add the custom key event
			if custom_key != KEY_NONE:
				var event = InputEventKey.new()
				event.keycode = custom_key
				InputMap.action_add_event(action, event)

func load_and_apply_settings():
	"""Load settings and apply proper volume calculations for game scene"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	var music_enabled = true
	var music_volume = 0.5  # Default 50%
	var sfx_volume = 0.5    # Default 50%
	
	if err == OK:
		music_enabled = config.get_value("audio", "music_enabled", true)
		music_volume = config.get_value("audio", "music_volume", 0.5)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.5)
	
	# Apply settings using proper volume calculations
	if music_enabled:
		# Calculate game scene music volume (50% = -5dB, 100% = 0dB)
		var game_volume_db = calculate_game_music_volume_db(music_volume)
		$"BackgroundMusic".volume_db = game_volume_db
	else:
		$"BackgroundMusic".volume_db = -80.0  # Muted
	
	# Calculate SFX volume (50% = 0dB, 100% = +10dB)
	var sfx_volume_db = calculate_sfx_volume_db(sfx_volume)
	$BallSound.volume_db = sfx_volume_db
	$Score.volume_db = sfx_volume_db
	$Button.volume_db = sfx_volume_db

func calculate_game_music_volume_db(volume_percent: float) -> float:
	"""Game scene: 50% = -5dB, 100% = 0dB, 0% = -80dB"""
	if volume_percent <= 0.0:
		return -80.0
	
	return lerp(-5.0, 0.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, -5.0, volume_percent / 0.5)

func calculate_sfx_volume_db(volume_percent: float) -> float:
	"""SFX: 50% = 0dB, 100% = +10dB, 0% = -80dB"""
	if volume_percent <= 0.0:
		return -80.0
	
	return lerp(0.0, 10.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, 0.0, volume_percent / 0.5)

func _on_background_music_finished():
	# Restart the music when it finishes
	$"BackgroundMusic".play()

func _on_back_to_menu_pressed():
	# Stop background music
	$"BackgroundMusic".stop()
	
	# Play button sound
	$Button.play()
	
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.1).timeout
	
	# Return to main menu
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# Optional: Add keyboard shortcut to return to menu
func _input(event):
	if event.is_action_pressed("ui_cancel"):  # Usually ESC key
		_on_back_to_menu_pressed()
