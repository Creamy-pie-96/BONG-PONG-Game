extends Node

const SAVE_PATH = "user://game_save.save"

var game_data = {
	"high_score": 0,
	"player_name": "Player",
	"sound_enabled": true,
	"difficulty": "normal"
}

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(game_data)
	file.close()
	print("Game saved!")

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		game_data = file.get_var()
		file.close()
		print("Game loaded!")
	else:
		print("No save file found, using defaults")

func update_high_score(new_score):
	if new_score > game_data.high_score:
		game_data.high_score = new_score
		save_game()  # Auto-save when high score is beaten
		print("New high score: ", new_score)

# Example usage
func _ready():
	load_game()
	print("High score: ", game_data.high_score)

func _on_game_over(final_score):
	update_high_score(final_score)
