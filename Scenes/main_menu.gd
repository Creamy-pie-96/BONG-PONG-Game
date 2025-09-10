extends Control

# Scene paths
const GAME_SCENE = "res://Scenes/background.tscn"
const SETTINGS_SCENE = "res://Scenes/settings.tscn"
var settings_scene_instance = null  # Will hold the loaded settings scene

func _ready():
	# Center the menu and set focus to play button
	$VBoxContainer/SinglePlayer.grab_focus()
	
	# Connect finished signal to restart music (for WAV files)
	$"BackgroundSound".finished.connect(_on_background_music_finished)
	
	# CORRECT way to load a scene for later use:
	var settings_scene = load(SETTINGS_SCENE)  # Load the scene resource
	settings_scene_instance = settings_scene.instantiate()  # Create instance
	
	# Load and apply initial settings
	apply_initial_settings()
	
	$"BackgroundSound".play()

func apply_initial_settings():
	"""Load settings and apply proper volume levels"""
	if settings_scene_instance:
		settings_scene_instance.load_setting()
		
		# Apply music settings
		if settings_scene_instance.back_music_on:
			# Calculate proper volume for menu scene
			var menu_volume_db = settings_scene_instance.calculate_music_volume_db(settings_scene_instance.music_volume, false)
			$"BackgroundSound".volume_db = menu_volume_db
		else:
			$"BackgroundSound".volume_db = -80.0  # Muted
		
		# Apply SFX volume
		var sfx_volume_db = settings_scene_instance.calculate_sfx_volume_db(settings_scene_instance.sfx_volume)
		$Button.volume_db = sfx_volume_db
	
func _on_background_music_finished():
	# Restart the music when it finishes
	$"BackgroundSound".play()


func _on_settings_button_pressed():
	$Button.play()
	
	# Wait for button sound to play
	await get_tree().create_timer(0.3).timeout
	
	# Method 1: Show settings as a popup (recommended for now)
	if settings_scene_instance:
		# Only add as child if not already added
		if not settings_scene_instance.get_parent():
			add_child(settings_scene_instance)
			
			# Connect to settings changes only once
			settings_scene_instance.music_toggled.connect(_on_music_setting_changed)
			settings_scene_instance.music_volume_changed.connect(_on_music_volume_changed)
			settings_scene_instance.sfx_volume_changed.connect(_on_sfx_volume_changed)
			settings_scene_instance.ball_speed_changed.connect(_on_ball_speed_changed)
			settings_scene_instance.gravity_changed.connect(_on_gravity_changed)
			settings_scene_instance.ai_difficulty_changed.connect(_on_ai_difficulty_changed)
		
		settings_scene_instance.show()
	else:
		# Fallback: Show dialog
		var dialog = AcceptDialog.new()
		dialog.title = "Settings"
		dialog.dialog_text = "Settings menu coming soon!\n\nControls:\nPlayer 1: W-A-S-D & Q-E keys\nPlayer 2: 8-4-2-6 & 7-9"
		add_child(dialog)
		dialog.popup_centered()

func _on_music_setting_changed(enabled: bool):
	if enabled:
		# Apply proper volume when enabling music
		var menu_volume_db = settings_scene_instance.calculate_music_volume_db(settings_scene_instance.music_volume, false)
		$"BackgroundSound".volume_db = menu_volume_db
		if !$"BackgroundSound".is_playing():
			$"BackgroundSound".play()
	else:
		$"BackgroundSound".volume_db = -80.0  # Muted
		if $"BackgroundSound".is_playing():
			$"BackgroundSound".stop()

func _on_music_volume_changed(volume: float):
	# Use proper volume calculation for menu scene
	var menu_volume_db = settings_scene_instance.calculate_music_volume_db(volume, false)
	$"BackgroundSound".volume_db = menu_volume_db

func _on_sfx_volume_changed(volume: float):
	# Use proper SFX volume calculation
	var sfx_volume_db = settings_scene_instance.calculate_sfx_volume_db(volume)
	$Button.volume_db = sfx_volume_db

func _on_ball_speed_changed(speed: float):
	# This will be applied when the game starts
	print("Ball speed changed to: ", speed)

func _on_gravity_changed(gravity: float):
	# This will be applied when the game starts
	print("Gravity changed to: ", gravity)

func _on_ai_difficulty_changed(difficulty: float):
	# Update GameState with new AI difficulty
	if has_node("/root/GameState"):
		GameState.ai_difficulty = difficulty
	print("AI difficulty changed to: ", difficulty)

func _on_quit_button_pressed():
	$Button.play()
	
	# Wait for button sound to play before quitting
	await get_tree().create_timer(0.3).timeout
	
	# Quit the game
	get_tree().quit()

# Handle keyboard navigation
func _input(event):
	# Only handle input if the main menu is actually visible and no settings are open
	if not visible:
		return
	
	# Check if settings scene is open
	if settings_scene_instance and settings_scene_instance.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_quit_button_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if $VBoxContainer/SinglePlayer.has_focus():
			_on_single_player_pressed()
		elif $VBoxContainer/MultiPlayer.has_focus():
			_on_multi_player_pressed()
		elif $VBoxContainer/AIvsAI.has_focus():
			_on_ai_vs_ai_pressed()
		elif $VBoxContainer/SettingsButton.has_focus():
			_on_settings_button_pressed()
		elif $VBoxContainer/QuitButton.has_focus():
			_on_quit_button_pressed()
		get_viewport().set_input_as_handled()


func _on_multi_player_pressed() -> void:
	$Button.play()
	$"BackgroundSound".stop()
	
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	
	# Set multiplayer mode and ensure AI vs AI is disabled
	if has_node("/root/GameState"):
		GameState.is_multiplayer = true
		GameState.is_ai_vs_ai = false  # Explicitly disable AI vs AI mode
		# Load AI difficulty from settings
		if settings_scene_instance:
			GameState.ai_difficulty = settings_scene_instance.ai_difficulty
	
	# Transition to the game scene
	get_tree().change_scene_to_file(GAME_SCENE)
	
	# Note: Volume settings will be applied when the background scene loads
	# The background scene will read the settings from the config file


func _on_single_player_pressed() -> void:
	$Button.play()
	$"BackgroundSound".stop()
	
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	
	# Go to side selection for single player
	get_tree().change_scene_to_file("res://Scenes/side_selection.tscn")

func _on_ai_vs_ai_pressed() -> void:
	$Button.play()
	$"BackgroundSound".stop()
	
	# Wait for button sound to play before transitioning
	await get_tree().create_timer(0.3).timeout
	
	# Go to AI vs AI setup
	get_tree().change_scene_to_file("res://Scenes/ai_vs_ai_setup.tscn")
