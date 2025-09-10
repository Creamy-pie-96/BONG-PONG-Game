extends Node2D

signal music_toggled(enabled: bool)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal ball_speed_changed(speed: float)
signal gravity_changed(gravity: float)
signal ai_difficulty_changed(difficulty: float)

var back_music_on : bool = true
var music_volume : float = 0.5  # Default to 50%
var sfx_volume : float = 0.5    # Default to 50%
var ball_speed : float = 1.0    # Default 100% (900 speed)
var gravity : float = 0.5       # Default 50% (0 gravity)
var ai_difficulty : float = 0.5  # Default 50% (medium difficulty)

func _ready():
	# Load settings FIRST before setting UI elements
	load_setting()
	
	# THEN set UI elements to match loaded values
	update_ui_from_settings()

func update_ui_from_settings():
	"""Update all UI elements to match current setting values"""
	$CheckButton.button_pressed = back_music_on
	$HSlider.value = music_volume      # Music volume slider
	$HSlider3.value = sfx_volume       # SFX volume slider  
	$HSlider2.value = ball_speed       # Ball speed slider
	$HSlider4.value = gravity          # Gravity slider
	if get_node_or_null("AiDifficultiHSlider"):
		$AiDifficultiHSlider.value = ai_difficulty    # AI difficulty slider
	
	# Update percentage displays
	update_percentage_display("MusicVolumePercent", music_volume)
	update_percentage_display("SFXVolumePercent", sfx_volume)
	update_percentage_display("BallSpeedPercent", ball_speed)
	update_percentage_display("GravityPercent", gravity)
	update_percentage_display("AiDifficultyPercent", ai_difficulty)

func update_percentage_display(label_name: String, value: float):
	"""Update percentage label with current value"""
	var label = get_node_or_null(label_name)
	if label:
		var percentage: int
		
		# Special handling for ball speed (50% to 150% range)
		if label_name == "BallSpeedPercent":
			# Map 0.0-1.0 to 50%-150%
			percentage = int(round(50 + (value * 100)))
		else:
			# Normal 0% to 100% range
			percentage = int(round(value * 100))
		
		label.text = str(percentage) + "%"

func calculate_music_volume_db(volume_percent: float, is_game_scene: bool = false) -> float:
	"""
	Calculate dB value based on volume percentage
	50% = 0dB (menu), -5dB (game)
	100% = +10dB (menu), 0dB (game)
	0% = -80dB (muted)
	"""
	if volume_percent <= 0.0:
		return -80.0  # Muted
	
	if is_game_scene:
		# Game scene: 50% = -5dB, 100% = 0dB
		return lerp(-5.0, 0.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, -5.0, volume_percent / 0.5)
	else:
		# Menu scene: 50% = 0dB, 100% = +10dB
		return lerp(0.0, 10.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, 0.0, volume_percent / 0.5)

func calculate_sfx_volume_db(volume_percent: float) -> float:
	"""
	Calculate SFX dB value
	50% = 0dB, 100% = +10dB, 0% = -80dB
	"""
	if volume_percent <= 0.0:
		return -80.0
	
	return lerp(0.0, 10.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, 0.0, volume_percent / 0.5)

func _on_check_button_toggled(toggled_on: bool) -> void:
	back_music_on = toggled_on
	emit_signal("music_toggled", back_music_on)
	save_setting()

func _on_music_volume_changed(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	emit_signal("music_volume_changed", music_volume)
	update_percentage_display("MusicVolumePercent", music_volume)
	save_setting()

func _on_sfx_volume_changed(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	emit_signal("sfx_volume_changed", sfx_volume)
	update_percentage_display("SFXVolumePercent", sfx_volume)
	save_setting()

func _on_ball_speed_changed(value: float):
	ball_speed = clamp(value, 0.0, 1.0)
	emit_signal("ball_speed_changed", ball_speed)
	update_percentage_display("BallSpeedPercent", ball_speed)
	save_setting()

func _on_gravity_changed(value: float):
	gravity = clamp(value, 0.0, 1.0)
	emit_signal("gravity_changed", gravity)
	update_percentage_display("GravityPercent", gravity)
	save_setting()

func _on_ai_difficulty_changed(value: float):
	ai_difficulty = clamp(value, 0.0, 1.0)
	emit_signal("ai_difficulty_changed", ai_difficulty)
	update_percentage_display("AiDifficultyPercent", ai_difficulty)
	save_setting()

func _on_fullscreen_pressed():
	$ButtonSound.play()
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_controls_pressed():
	$ButtonSound.play()
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	# Load the controls scene
	var controls_scene = preload("res://Scenes/controls.tscn")
	var controls_instance = controls_scene.instantiate()
	get_parent().add_child(controls_instance)
	controls_instance.show()
	
	# Hide the settings panel while controls are open
	hide()

func _on_graphics_pressed():
	$ButtonSound.play()
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	var dialog = AcceptDialog.new()
	dialog.title = "Graphics Settings"
	dialog.dialog_text = "Graphics settings coming soon!\n\nCurrent resolution: " + str(DisplayServer.window_get_size())
	add_child(dialog)
	dialog.popup_centered()

func _on_back_pressed():
	$ButtonSound.play()
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	hide()  # Hide the settings panel

func save_setting():
	var config = ConfigFile.new()
	config.set_value("audio", "music_enabled", back_music_on)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("gameplay", "ball_speed", ball_speed)
	config.set_value("gameplay", "gravity", gravity)
	config.set_value("gameplay", "ai_difficulty", ai_difficulty)
	config.save("user://settings.cfg")

func load_setting():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		back_music_on = config.get_value("audio", "music_enabled", true)
		music_volume = config.get_value("audio", "music_volume", 0.5)  # Default 50%
		sfx_volume = config.get_value("audio", "sfx_volume", 0.5)      # Default 50%
		ball_speed = config.get_value("gameplay", "ball_speed", 0.5)   # Default 100% (slider middle)
		gravity = config.get_value("gameplay", "gravity", 0.5)         # Default 50%
		ai_difficulty = config.get_value("gameplay", "ai_difficulty", 0.5) # Default 50%
	else:
		# If no config file exists, use defaults
		back_music_on = true
		music_volume = 0.5
		sfx_volume = 0.5
		ball_speed = 0.5
		gravity = 0.5
		ai_difficulty = 0.5

# Add close functionality
func _input(event):
	# Only handle input if settings are visible
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()  # Stop the event from propagating
