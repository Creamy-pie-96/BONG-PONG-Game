extends Control

const GAME_SCENE = "res://Scenes/background.tscn"
const MAIN_MENU_SCENE = "res://Scenes/main_menu.tscn"

func _on_player_1_button_pressed():
	# Set player to control Player 1 (left side)
	if has_node("/root/GameState"):
		GameState.is_multiplayer = false
		GameState.is_ai_vs_ai = false
		GameState.player_side = "left"
		# Load AI difficulty from main menu settings
		GameState.ai_difficulty = 0.5  # Default, will be overridden by settings
	
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_player_2_button_pressed():
	# Set player to control Player 2 (right side)
	if has_node("/root/GameState"):
		GameState.is_multiplayer = false
		GameState.is_ai_vs_ai = false
		GameState.player_side = "right"
		# Load AI difficulty from main menu settings
		GameState.ai_difficulty = 0.5  # Default, will be overridden by settings
	
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_back_button_pressed():
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
		get_viewport().set_input_as_handled()
