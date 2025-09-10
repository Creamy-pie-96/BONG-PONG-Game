extends CharacterBody2D

@export var speed: float = 500
@export var rotation_speed: float = 1.3
@export var rot_restore_speed: float = 2.0
@export var max_rotation_deg: float = 22.0
@export var min_rotation_deg: float = -22.0
@export var mass : float = 20.0

var Player1_max_x: float = 280.0
var Player1_min_x: float = 49.0
var Player2_max_x: float = 1231.0
var Player2_min_x: float = 1000.0

# Screen size variables for dynamic positioning
var screen_width: float = 1280.0
var screen_height: float = 720.0
var screen_center_x: float = 640.0
var screen_center_y: float = 360.0

# AI System Variables
var is_ai_enabled: bool = false
var is_ai_vs_ai: bool = false
var player_side: String = "left"  # For single player mode
var ball_node: RigidBody2D = null
var ai_reaction_timer: float = 0.0
var ai_target_y: float = 360.0
var ai_target_x: float = 1208.0  # AI's target X position for strategic movement
var ai_state: String = "TRACKING"  # TRACKING, INTERCEPTING, REPOSITIONING

# AI parameters for Player 1 (when in AI vs AI mode)
var ai_1_reaction_timer: float = 0.0
var ai_1_target_y: float = 360.0
var ai_1_target_x: float = 72.0
var ai_1_state: String = "TRACKING"

# AI Behavior Parameters (from GameState)
var ai_precision: float = 0.5
var ai_reaction_time: float = 0.15
var ai_prediction_accuracy: float = 0.7
var ai_movement_smoothness: float = 0.8

# AI parameters for Player 1 in AI vs AI mode
var ai_1_precision: float = 0.5
var ai_1_reaction_time: float = 0.15
var ai_1_prediction_accuracy: float = 0.7
var ai_1_movement_smoothness: float = 0.8

func _ready() -> void:
	# Get screen size for dynamic positioning
	var viewport = get_viewport()
	screen_width = viewport.get_visible_rect().size.x
	screen_height = viewport.get_visible_rect().size.y
	screen_center_x = screen_width / 2.0
	screen_center_y = screen_height / 2.0
	
	# Initialize AI targets with dynamic values
	ai_target_y = screen_center_y
	ai_1_target_y = screen_center_y
	
	# Initial positions
	$"../Player 2".position = Vector2(1208.0, screen_center_y)
	$"../Player 1".position = Vector2(72.0, screen_center_y)
	$"../Player 2".rotation = 0.0
	$"../Player 1".rotation = 0.0
	
	# Get ball reference
	ball_node = get_parent().get_node_or_null("Ball")
	
	# Check game mode from GameState
	if has_node("/root/GameState"):
		is_ai_vs_ai = GameState.is_ai_vs_ai
		player_side = GameState.player_side
		
		if is_ai_vs_ai:
			# Both players are AI
			is_ai_enabled = true
			update_ai_parameters()
			update_ai_1_parameters()
		else:
			# Single player or multiplayer
			is_ai_enabled = not GameState.is_multiplayer
			if is_ai_enabled:
				update_ai_parameters()
	
	print("AI vs AI: ", is_ai_vs_ai, " | AI enabled: ", is_ai_enabled, " | Player side: ", player_side)

func update_ai_parameters():
	"""Update AI behavior parameters based on GameState difficulty"""
	if has_node("/root/GameState"):
		# For Player 2 (right side) - use main AI difficulty or ai_2_difficulty in AI vs AI mode
		var difficulty = GameState.ai_2_difficulty if is_ai_vs_ai else GameState.ai_difficulty
		ai_precision = GameState.get_ai_precision_for_difficulty(difficulty)
		ai_reaction_time = GameState.get_ai_reaction_time_for_difficulty(difficulty)
		ai_prediction_accuracy = GameState.get_ai_prediction_accuracy_for_difficulty(difficulty)
		ai_movement_smoothness = GameState.get_ai_movement_smoothness_for_difficulty(difficulty)
		print("Player 2 AI Parameters - Precision: ", ai_precision, " Reaction: ", ai_reaction_time, " Prediction: ", ai_prediction_accuracy)

func update_ai_1_parameters():
	"""Update AI parameters for Player 1 in AI vs AI mode"""
	if has_node("/root/GameState") and is_ai_vs_ai:
		var difficulty = GameState.ai_1_difficulty
		ai_1_precision = GameState.get_ai_precision_for_difficulty(difficulty)
		ai_1_reaction_time = GameState.get_ai_reaction_time_for_difficulty(difficulty)
		ai_1_prediction_accuracy = GameState.get_ai_prediction_accuracy_for_difficulty(difficulty)
		ai_1_movement_smoothness = GameState.get_ai_movement_smoothness_for_difficulty(difficulty)
		print("Player 1 AI Parameters - Precision: ", ai_1_precision, " Reaction: ", ai_1_reaction_time, " Prediction: ", ai_1_prediction_accuracy)

func _process(delta: float) -> void:
	# Convert degrees to radians for clamping
	var max_rotation = deg_to_rad(max_rotation_deg)
	var min_rotation = deg_to_rad(min_rotation_deg)

	# Handle different game modes
	if is_ai_vs_ai:
		# AI vs AI mode - both players are controlled by AI
		if ball_node:
			handle_ai_player_1(delta)
			handle_ai_player_2(delta)
	elif is_ai_enabled:
		# Single player mode - one human, one AI
		if player_side == "left":
			# Human controls Player 1, AI controls Player 2
			handle_human_player_1(delta)
			if ball_node:
				handle_ai_player_2(delta)
		else:
			# Human controls Player 2, AI controls Player 1  
			if ball_node:
				handle_ai_player_1(delta)
			handle_human_player_2(delta)
	else:
		# Multiplayer mode - both players are human
		handle_human_player_1(delta)
		handle_human_player_2(delta)

func handle_human_player_1(delta: float):
	"""Handle human input for Player 1"""
	var p1_max_rotation = deg_to_rad(max_rotation_deg)
	var p1_min_rotation = deg_to_rad(min_rotation_deg)
	
	var dir_p1 = Input.get_vector("Left__player1", "Right__player1", "Up__player1", "Down__player1")
	var rot_p1 = 0
	var is_rotating_p1 = false
	if Input.is_action_pressed("Rotate_clockwise__player1"):
		rot_p1 = 1
		is_rotating_p1 = true
	elif Input.is_action_pressed("Rotate_anticlockwise__player1"):
		rot_p1 = -1
		is_rotating_p1 = true

	$"../Player 1".velocity = dir_p1 * speed
	$"../Player 1".move_and_slide()
	$"../Player 1".position.x = clamp($"../Player 1".position.x, Player1_min_x, Player1_max_x)

	if is_rotating_p1:
		$"../Player 1".rotation += rot_p1 * rotation_speed * delta
	else:
		# Smoothly restore rotation to 0 when not rotating
		$"../Player 1".rotation = lerp_angle($"../Player 1".rotation, 0, rot_restore_speed * delta)

	$"../Player 1".rotation = clamp($"../Player 1".rotation, p1_min_rotation, p1_max_rotation)

func handle_ai_player_1(delta: float):
	"""AI system for Player 1 (left side)"""
	var player_p1 = $"../Player 1"
	var p1_max_rotation = deg_to_rad(max_rotation_deg)
	var p1_min_rotation = deg_to_rad(min_rotation_deg)
	
	# Update AI reaction timer
	ai_1_reaction_timer += delta
	
	# Get current ball state
	var ball_pos = ball_node.position
	var ball_vel = ball_node.linear_velocity
	
	# Calculate relative distance and approach direction for Player 1 (left side)
	var distance_to_ball_x = abs(ball_pos.x - player_p1.position.x)
	var ball_approaching = ball_vel.x < 0  # Ball moving toward Player 1 (left side)
	var ball_past_center = ball_pos.x < screen_center_x  # Ball past center line toward Player 1
	
	# AI State Machine for Player 1
	match ai_1_state:
		"TRACKING":
			if ball_approaching and ball_past_center:  # Ball approaching and past center
				ai_1_state = "INTERCEPTING"
		"INTERCEPTING":
			if not ball_approaching or not ball_past_center:  # Ball moving away or back to center
				ai_1_state = "REPOSITIONING"
		"REPOSITIONING":
			if ball_approaching and ball_past_center:
				ai_1_state = "INTERCEPTING"
			elif abs(player_p1.position.y - screen_center_y) < 50:  # Close to center
				ai_1_state = "TRACKING"
	
	# Only update targets when reaction timer allows (based on difficulty)
	if ai_1_reaction_timer >= ai_1_reaction_time:
		# Calculate target positions for Player 1
		var new_target_y = calculate_ai_1_target_y(ball_pos, ball_vel, ball_approaching, player_p1.position)
		var new_target_x = calculate_ai_1_target_x(ball_pos, ball_vel, ball_approaching, player_p1.position)
		
		# Apply precision error based on difficulty
		if ai_1_precision < 1.0:
			var error_magnitude = (1.0 - ai_1_precision) * 100.0
			new_target_y += randf_range(-error_magnitude, error_magnitude)
			
			# Less horizontal movement error for better gameplay
			var x_error = (1.0 - ai_1_precision) * 30.0
			new_target_x += randf_range(-x_error, x_error)
		
		ai_1_target_y = new_target_y
		ai_1_target_x = new_target_x
		ai_1_reaction_timer = 0.0
	
	# Clamp targets to playable area
	ai_1_target_y = clamp(ai_1_target_y, 60, screen_height - 60)
	ai_1_target_x = clamp(ai_1_target_x, Player1_min_x, Player1_max_x)
	
	# Calculate movement for both axes
	var p1_current_pos = player_p1.position
	var p1_distance_to_target_y = ai_1_target_y - p1_current_pos.y
	var p1_distance_to_target_x = ai_1_target_x - p1_current_pos.x
	var p1_movement_speed = calculate_ai_1_movement_speed(p1_distance_to_target_y, ball_approaching)
	
	# Apply movement with smoothness
	var p1_move_y = sign(p1_distance_to_target_y) * min(abs(p1_distance_to_target_y) / 50.0, 1.0) * ai_1_movement_smoothness
	var p1_move_x = sign(p1_distance_to_target_x) * min(abs(p1_distance_to_target_x) / 80.0, 0.3) * ai_1_movement_smoothness
	
	var p1_dir = Vector2(p1_move_x, p1_move_y).normalized() * Vector2(p1_move_x, p1_move_y).length()
	
	player_p1.velocity = p1_dir * speed * p1_movement_speed
	player_p1.move_and_slide()
	player_p1.position.x = clamp(player_p1.position.x, Player1_min_x, Player1_max_x)
	
	# AI rotation logic for Player 1
	handle_ai_1_rotation(player_p1, ball_pos, ball_vel, ball_approaching, delta, p1_min_rotation, p1_max_rotation)

func handle_ai_player_2(delta: float):
	"""Advanced AI system for Player 2 with difficulty-based behaviors"""
	var player_p2 = $"../Player 2"
	var p2_max_rotation = deg_to_rad(max_rotation_deg)
	var p2_min_rotation = deg_to_rad(min_rotation_deg)
	
	# Update AI reaction timer
	ai_reaction_timer += delta
	
	# Get current ball state
	var ball_pos = ball_node.position
	var ball_vel = ball_node.linear_velocity
	
	# Calculate relative distance and approach direction for Player 2 (right side)
	var distance_to_ball_x = abs(ball_pos.x - player_p2.position.x)
	var ball_approaching = ball_vel.x > 0  # Ball moving toward Player 2 (right side)
	var ball_past_center = ball_pos.x > screen_center_x  # Ball past center line toward Player 2
	
	# AI State Machine
	match ai_state:
		"TRACKING":
			if ball_approaching and ball_past_center:  # Ball approaching and past center
				ai_state = "INTERCEPTING"
		"INTERCEPTING":
			if not ball_approaching or not ball_past_center:  # Ball moving away or back to center
				ai_state = "REPOSITIONING"
		"REPOSITIONING":
			if ball_approaching and ball_past_center:
				ai_state = "INTERCEPTING"
			elif abs(player_p2.position.y - screen_center_y) < 50:  # Close to center
				ai_state = "TRACKING"
	
	# Only update targets when reaction timer allows (based on difficulty)
	if ai_reaction_timer >= ai_reaction_time:
		# Calculate target positions based on AI state and difficulty
		var new_target_y = calculate_ai_target_y(ball_pos, ball_vel, ball_approaching, player_p2.position)
		var new_target_x = calculate_ai_target_x(ball_pos, ball_vel, ball_approaching, player_p2.position)
		
		# Apply precision error based on difficulty
		if ai_precision < 1.0:
			var error_magnitude = (1.0 - ai_precision) * 100.0
			new_target_y += randf_range(-error_magnitude, error_magnitude)
			
			# Less horizontal movement error for better gameplay
			var x_error = (1.0 - ai_precision) * 30.0
			new_target_x += randf_range(-x_error, x_error)
		
		ai_target_y = new_target_y
		ai_target_x = new_target_x
		ai_reaction_timer = 0.0
	
	# Clamp targets to playable area
	ai_target_y = clamp(ai_target_y, 60, screen_height - 60)
	ai_target_x = clamp(ai_target_x, Player2_min_x, Player2_max_x)
	
	# Calculate movement for both axes
	var p2_current_pos = player_p2.position
	var p2_distance_to_target_y = ai_target_y - p2_current_pos.y
	var p2_distance_to_target_x = ai_target_x - p2_current_pos.x
	var p2_movement_speed = calculate_ai_movement_speed(p2_distance_to_target_y, ball_approaching)
	
	# Apply movement with smoothness
	var p2_move_y = sign(p2_distance_to_target_y) * min(abs(p2_distance_to_target_y) / 50.0, 1.0) * ai_movement_smoothness
	var p2_move_x = sign(p2_distance_to_target_x) * min(abs(p2_distance_to_target_x) / 80.0, 0.3) * ai_movement_smoothness  # Smaller X movement
	
	var p2_dir = Vector2(p2_move_x, p2_move_y).normalized() * Vector2(p2_move_x, p2_move_y).length()
	
	player_p2.velocity = p2_dir * speed * p2_movement_speed
	player_p2.move_and_slide()
	player_p2.position.x = clamp(player_p2.position.x, Player2_min_x, Player2_max_x)
	
	# AI rotation logic - strategic angling
	handle_ai_rotation(player_p2, ball_pos, ball_vel, ball_approaching, delta, p2_min_rotation, p2_max_rotation)

func calculate_ai_target_y(ball_pos: Vector2, ball_vel: Vector2, _ball_approaching: bool, player_pos: Vector2) -> float:
	"""Calculate optimal target position based on game state and AI difficulty"""
	var target_y: float
	
	match ai_state:
		"TRACKING":
			# Follow ball with some offset based on difficulty
			target_y = ball_pos.y
			if ai_precision > 0.7:  # High difficulty - predict slight deflections
				target_y += ball_vel.y * 0.1
		
		"INTERCEPTING":
			# Predict ball intersection point
			var player_x = player_pos.x
			var time_to_reach = 0.0
			
			if abs(ball_vel.x) > 10.0:
				time_to_reach = (player_x - ball_pos.x) / ball_vel.x
				time_to_reach = max(0.0, time_to_reach)  # Only future predictions
			
			# Base prediction
			target_y = ball_pos.y + ball_vel.y * time_to_reach
			
			# Apply prediction accuracy
			if ai_prediction_accuracy < 1.0:
				var prediction_error = (1.0 - ai_prediction_accuracy) * 150.0
				target_y += randf_range(-prediction_error, prediction_error)
			
			# Strategic positioning based on difficulty
			if ai_precision > 0.8:  # Expert level - try to aim returns
				var optimal_angle = calculate_optimal_return_angle(ball_pos, ball_vel)
				target_y += optimal_angle * 30.0  # Adjust position for better returns
		
		"REPOSITIONING":
			# Return to center or strategic position
			if ai_precision > 0.6:
				target_y = screen_center_y + randf_range(-50, 50)  # Slight variation from center
			else:
				target_y = screen_center_y  # Just go to center
	
	return target_y

func calculate_ai_target_x(ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, player_pos: Vector2) -> float:
	"""Calculate optimal X position for strategic movement"""
	var target_x = player_pos.x  # Default: stay in current position
	
	# Only move horizontally at higher difficulties
	if ai_precision > 0.4:
		match ai_state:
			"INTERCEPTING":
				if ball_approaching:
					# Move forward slightly to apply more force to the ball
					if ai_precision > 0.7:
						target_x = Player2_min_x + 50  # Move forward for aggressive returns
					else:
						target_x = Player2_min_x + 100  # Conservative forward movement
			
			"REPOSITIONING":
				# Return to optimal defensive position
				target_x = Player2_min_x + 150  # Middle defensive position
			
			"TRACKING":
				# Stay in neutral position but adjust based on ball speed
				if abs(ball_vel.x) > 500 and ai_precision > 0.6:  # Fast ball approaching
					target_x = Player2_min_x + 80  # Prepare for aggressive return
				else:
					target_x = Player2_min_x + 120  # Standard position
	
	return target_x

func calculate_ai_movement_speed(distance_to_target: float, ball_approaching: bool) -> float:
	"""Calculate movement speed multiplier based on urgency and difficulty"""
	var base_speed = 1.0
	var urgency_multiplier = 1.0
	
	# Increase speed when ball is approaching and AI needs to move
	if ball_approaching and abs(distance_to_target) > 30:
		urgency_multiplier = 1.2 + (ai_precision * 0.3)  # Faster reaction at higher difficulty
	
	# Reduce speed for lower difficulties (more human-like)
	var difficulty_speed = 0.7 + (ai_precision * 0.3)
	
	return base_speed * urgency_multiplier * difficulty_speed

func handle_ai_rotation(player: CharacterBody2D, ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, delta: float, min_rot: float, max_rot: float):
	"""Handle AI paddle rotation for strategic returns"""
	var target_rotation = 0.0
	
	if ball_approaching and ai_precision > 0.5:
		# Calculate desired return angle based on ball trajectory
		var return_angle = calculate_optimal_return_angle(ball_pos, ball_vel)
		target_rotation = clamp(return_angle, min_rot, max_rot)
		
		# Apply rotation with some imprecision at lower difficulties
		if ai_precision < 1.0:
			var rotation_error = (1.0 - ai_precision) * 0.3
			target_rotation += randf_range(-rotation_error, rotation_error)
	
	# Smooth rotation toward target
	var ai_rotation_speed = rotation_speed * (0.5 + ai_precision * 0.5)  # Faster rotation at higher difficulty
	player.rotation = lerp_angle(player.rotation, target_rotation, ai_rotation_speed * delta)
	player.rotation = clamp(player.rotation, min_rot, max_rot)

func calculate_optimal_return_angle(ball_pos: Vector2, _ball_vel: Vector2) -> float:
	"""Calculate optimal paddle angle for strategic returns"""
	# Simple strategy: try to return ball toward opponent's weak spots
	var player1_pos = $"../Player 1".position
	var target_area_y: float
	
	# Target the area farthest from Player 1
	if player1_pos.y < screen_center_y:
		target_area_y = screen_center_y + 140  # Aim low if Player 1 is high
	else:
		target_area_y = screen_center_y - 140  # Aim high if Player 1 is low
	
	# Calculate angle needed to reach target area
	var angle_factor = (target_area_y - ball_pos.y) / 200.0
	return clamp(angle_factor, -0.4, 0.4)  # Limit to reasonable angles

func handle_human_player_2(delta: float):
	"""Original human player 2 controls"""
	var max_rotation = deg_to_rad(max_rotation_deg)
	var min_rotation = deg_to_rad(min_rotation_deg)
	
	var dir_p2 = Input.get_vector("Left_player2", "Right_player2", "Up_player2", "Down_player2")
	var rot_p2 = 0
	var is_rotating_p2 = false
	if Input.is_action_pressed("Rotate_clockwise__player2"):
		rot_p2 = 1
		is_rotating_p2 = true
	elif Input.is_action_pressed("Rotate_anticlockwise__player2"):
		rot_p2 = -1
		is_rotating_p2 = true

	$"../Player 2".velocity = dir_p2 * speed
	$"../Player 2".move_and_slide()
	$"../Player 2".position.x = clamp($"../Player 2".position.x, Player2_min_x, Player2_max_x)

	if is_rotating_p2:
		$"../Player 2".rotation += rot_p2 * rotation_speed * delta
	else:
		# Smoothly restore rotation to 0 when not rotating
		$"../Player 2".rotation = lerp_angle($"../Player 2".rotation, 0, rot_restore_speed * delta)

	$"../Player 2".rotation = clamp($"../Player 2".rotation, min_rotation, max_rotation)

# Player 1 AI Functions (mirror of Player 2 AI but adapted for left side)
func calculate_ai_1_target_y(ball_pos: Vector2, ball_vel: Vector2, _ball_approaching: bool, player_pos: Vector2) -> float:
	"""Calculate optimal target position for Player 1 AI"""
	var target_y: float
	
	match ai_1_state:
		"TRACKING":
			target_y = ball_pos.y
			if ai_1_precision > 0.7:
				target_y += ball_vel.y * 0.1
		
		"INTERCEPTING":
			var player_x = player_pos.x
			var time_to_reach = 0.0
			
			if abs(ball_vel.x) > 10.0:
				time_to_reach = (player_x - ball_pos.x) / ball_vel.x
				time_to_reach = max(0.0, time_to_reach)
			
			target_y = ball_pos.y + ball_vel.y * time_to_reach
			
			if ai_1_prediction_accuracy < 1.0:
				var prediction_error = (1.0 - ai_1_prediction_accuracy) * 150.0
				target_y += randf_range(-prediction_error, prediction_error)
			
			if ai_1_precision > 0.8:
				var optimal_angle = calculate_optimal_return_angle_p1(ball_pos, ball_vel)
				target_y += optimal_angle * 30.0
		
		"REPOSITIONING":
			if ai_1_precision > 0.6:
				target_y = screen_center_y + randf_range(-50, 50)
			else:
				target_y = screen_center_y
	
	return target_y

func calculate_ai_1_target_x(ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, player_pos: Vector2) -> float:
	"""Calculate optimal X position for Player 1 AI"""
	var target_x = player_pos.x
	
	if ai_1_precision > 0.4:
		match ai_1_state:
			"INTERCEPTING":
				if ball_approaching:
					if ai_1_precision > 0.7:
						target_x = Player1_max_x - 50  # Move forward for aggressive returns
					else:
						target_x = Player1_max_x - 100
			
			"REPOSITIONING":
				target_x = Player1_max_x - 150  # Middle defensive position
			
			"TRACKING":
				if abs(ball_vel.x) > 500 and ai_1_precision > 0.6:
					target_x = Player1_max_x - 80
				else:
					target_x = Player1_max_x - 120
	
	return target_x

func calculate_ai_1_movement_speed(distance_to_target: float, ball_approaching: bool) -> float:
	"""Calculate movement speed for Player 1 AI"""
	var base_speed = 1.0
	var urgency_multiplier = 1.0
	
	if ball_approaching and abs(distance_to_target) > 30:
		urgency_multiplier = 1.2 + (ai_1_precision * 0.3)
	
	var difficulty_speed = 0.7 + (ai_1_precision * 0.3)
	
	return base_speed * urgency_multiplier * difficulty_speed

func handle_ai_1_rotation(player: CharacterBody2D, ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, delta: float, min_rot: float, max_rot: float):
	"""Handle AI paddle rotation for Player 1"""
	var target_rotation = 0.0
	
	if ball_approaching and ai_1_precision > 0.5:
		var return_angle = calculate_optimal_return_angle_p1(ball_pos, ball_vel)
		target_rotation = clamp(return_angle, min_rot, max_rot)
		
		if ai_1_precision < 1.0:
			var rotation_error = (1.0 - ai_1_precision) * 0.3
			target_rotation += randf_range(-rotation_error, rotation_error)
	
	var ai_rotation_speed = rotation_speed * (0.5 + ai_1_precision * 0.5)
	player.rotation = lerp_angle(player.rotation, target_rotation, ai_rotation_speed * delta)
	player.rotation = clamp(player.rotation, min_rot, max_rot)

func calculate_optimal_return_angle_p1(ball_pos: Vector2, _ball_vel: Vector2) -> float:
	"""Calculate optimal paddle angle for Player 1 strategic returns"""
	var player2_pos = $"../Player 2".position
	var target_area_y: float
	
	# Target the area farthest from Player 2
	if player2_pos.y < screen_center_y:
		target_area_y = screen_center_y + 140  # Aim low if Player 2 is high
	else:
		target_area_y = screen_center_y - 140  # Aim high if Player 2 is low
	
	var angle_factor = (target_area_y - ball_pos.y) / 200.0
	return clamp(angle_factor, -0.4, 0.4)
