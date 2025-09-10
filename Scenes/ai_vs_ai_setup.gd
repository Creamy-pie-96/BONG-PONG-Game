extends Control

@onready var ai1_slider = $Panel/VBoxContainer/AI1Container/AI1SliderContainer/AI1Slider
@onready var ai1_percent_label = $Panel/VBoxContainer/AI1Container/AI1SliderContainer/AI1PercentLabel
@onready var ai2_slider = $Panel/VBoxContainer/AI2Container/AI2SliderContainer/AI2Slider
@onready var ai2_percent_label = $Panel/VBoxContainer/AI2Container/AI2SliderContainer/AI2PercentLabel

func _ready():
	# Initialize sliders with current GameState values
	ai1_slider.value = GameState.ai_1_difficulty
	ai2_slider.value = GameState.ai_2_difficulty
	_update_percent_labels()

func _update_percent_labels():
	ai1_percent_label.text = str(int(ai1_slider.value * 100)) + "%"
	ai2_percent_label.text = str(int(ai2_slider.value * 100)) + "%"

func _on_ai_1_slider_value_changed(value):
	GameState.ai_1_difficulty = value
	_update_percent_labels()

func _on_ai_2_slider_value_changed(value):
	GameState.ai_2_difficulty = value
	_update_percent_labels()

func _on_start_button_pressed():
	# Set up AI vs AI mode
	GameState.is_multiplayer = false
	GameState.is_ai_vs_ai = true
	GameState.player_side = "left"  # Doesn't matter for AI vs AI
	
	# Start the game
	get_tree().change_scene_to_file("res://Scenes/background.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
