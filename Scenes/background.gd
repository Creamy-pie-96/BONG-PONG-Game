extends Node2D

const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"

func _ready():
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
