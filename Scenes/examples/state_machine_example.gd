extends Node2D

# Example of a simple state machine
enum GameState {MENU, PLAYING, PAUSED, GAME_OVER}
var current_state = GameState.MENU

func _ready():
	change_state(GameState.MENU)

func change_state(new_state):
	current_state = new_state
	match current_state:
		GameState.MENU:
			show_menu()
		GameState.PLAYING:
			start_game()
		GameState.PAUSED:
			pause_game()
		GameState.GAME_OVER:
			show_game_over()

func show_menu():
	print("Showing menu...")

func start_game():
	print("Starting game...")

func pause_game():
	print("Game paused...")

func show_game_over():
	print("Game over...")

# Example of using the state machine
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			change_state(GameState.PAUSED)
		elif current_state == GameState.PAUSED:
			change_state(GameState.PLAYING)
