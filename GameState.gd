extends Node

# Game mode state
var is_multiplayer: bool = true
var is_ai_vs_ai: bool = false
var player_side: String = "left"  # "left" or "right" for single player mode

# AI difficulty settings
var ai_difficulty: float = 0.5  # 0.0 = Easy, 1.0 = Perfect
var ai_1_difficulty: float = 0.5  # For AI vs AI mode - Player 1 AI
var ai_2_difficulty: float = 0.5  # For AI vs AI mode - Player 2 AI

# AI behavior parameters based on difficulty
func get_ai_precision() -> float:
	"""Returns precision factor (0.1 to 1.0) based on difficulty"""
	return 0.1 + (ai_difficulty * 0.9)

func get_ai_reaction_time() -> float:
	"""Returns reaction time in seconds (0.05 to 0.5) - much more dramatic scaling"""
	return 0.5 - (ai_difficulty * 0.45)

func get_ai_prediction_accuracy() -> float:
	"""Returns prediction accuracy (0.3 to 1.0)"""
	return 0.3 + (ai_difficulty * 0.7)

func get_ai_movement_smoothness() -> float:
	"""Returns movement smoothness factor (0.5 to 1.0)"""
	return 0.5 + (ai_difficulty * 0.5)

# Additional methods for AI vs AI mode with specific difficulty parameters
func get_ai_precision_for_difficulty(difficulty: float) -> float:
	"""Returns precision factor (0.1 to 1.0) based on given difficulty"""
	return 0.1 + (difficulty * 0.9)

func get_ai_reaction_time_for_difficulty(difficulty: float) -> float:
	"""Returns reaction time in seconds (0.05 to 0.5) based on given difficulty"""
	return 0.5 - (difficulty * 0.45)

func get_ai_prediction_accuracy_for_difficulty(difficulty: float) -> float:
	"""Returns prediction accuracy (0.3 to 1.0) based on given difficulty"""
	return 0.3 + (difficulty * 0.7)

func get_ai_movement_smoothness_for_difficulty(difficulty: float) -> float:
	"""Returns movement smoothness factor (0.5 to 1.0) based on given difficulty"""
	return 0.5 + (difficulty * 0.5)
