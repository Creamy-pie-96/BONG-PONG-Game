# AI System Explanation

This document explains how the AI opponent works in your Pong game, with detailed code explanations for beginners.

## Overview

The AI system creates an intelligent computer opponent for single-player mode. The AI can:

- Track and predict ball movement
- Move strategically in both X and Y directions
- Adjust difficulty from very easy to perfect
- Use different strategies based on game state
- React realistically with human-like delays

## File Structure

### Main Files:

- `GameState.gd` - Global AI settings and difficulty parameters
- `player_1.gd` - Contains all AI logic
- `settings.gd` - AI difficulty setting
- `main_menu.gd` - Game mode selection (single vs multiplayer)

---

## How Single Player Mode Works

### 1. Game Mode Selection (main_menu.gd)

```gdscript
func _on_single_player_pressed() -> void:
	# Set single player mode
	if has_node("/root/GameState"):
		GameState.is_multiplayer = false
		# Load AI difficulty from settings
		if settings_scene_instance:
			GameState.ai_difficulty = settings_scene_instance.ai_difficulty

	get_tree().change_scene_to_file(GAME_SCENE)
```

**Explanation:**

- When "Single Player" is pressed, set `is_multiplayer = false`
- Load the AI difficulty from the settings panel
- Switch to the game scene
- **GameState** is a "singleton" - accessible from anywhere in the game

# AI System Explanation

This document explains how the AI opponent works in your Pong game, including single-player, AI vs AI, and side selection modes.

## Overview

The AI system creates intelligent computer opponents with multiple game modes:

- **Single Player**: Human vs AI with side selection (left or right)
- **AI vs AI**: Watch two AIs battle with independent difficulty settings
- **Multiplayer**: Traditional human vs human mode

The AI can:

- Track and predict ball movement
- Move strategically in both X and Y directions
- Adjust difficulty from very easy to perfect
- Use different strategies based on game state
- React realistically with human-like delays
- Support different difficulties for each AI in AI vs AI mode

## File Structure

### Main Files:

- `GameState.gd` - Global AI settings, game modes, and difficulty parameters
- `player_1.gd` - Contains all AI logic for both players
- `settings.gd` - AI difficulty setting for single player
- `main_menu.gd` - Game mode selection
- `side_selection.gd` - Player side selection for single player
- `ai_vs_ai_setup.gd` - AI difficulty selection for AI vs AI mode

---

## Game Modes

### 1. Single Player Mode

#### Side Selection

```gdscript
# side_selection.gd
func _on_left_side_button_pressed():
	GameState.is_multiplayer = false
	GameState.is_ai_vs_ai = false
	GameState.player_side = "left"  # Human plays as left player
	get_tree().change_scene_to_file("res://Scenes/background.tscn")
```

**How it works:**

- Player chooses to control left or right paddle
- AI controls the opposite side
- GameState tracks which side the human controls

### 2. AI vs AI Mode

#### Setup Screen

```gdscript
# ai_vs_ai_setup.gd
func _on_start_button_pressed():
	GameState.is_multiplayer = false
	GameState.is_ai_vs_ai = true
	GameState.ai_1_difficulty = ai1_slider.value  # Left AI difficulty
	GameState.ai_2_difficulty = ai2_slider.value  # Right AI difficulty
	get_tree().change_scene_to_file("res://Scenes/background.tscn")
```

**Features:**

- Independent difficulty sliders for each AI
- Real-time percentage display
- Both AIs use the same strategic algorithms but with different skill levels

### 3. Game Mode Detection (player_1.gd)

````gdscript
func _ready() -> void:
	if has_node("/root/GameState"):
		is_ai_vs_ai = GameState.is_ai_vs_ai
		player_side = GameState.player_side

		if is_ai_vs_ai:
			# Both players are AI
			is_ai_enabled = true
			update_ai_parameters()      # For Player 2
			update_ai_1_parameters()    # For Player 1
**Explanation:**
- GameState tracks which mode is active
- Different parameters are loaded for each AI
- Each AI operates independently with its own difficulty

---

## Main Processing Logic

### Game Mode Handling (_process function)
```gdscript
func _process(delta: float) -> void:
	if is_ai_vs_ai:
		# AI vs AI mode - both players are controlled by AI
		if ball_node:
			handle_ai_player_1(delta)  # Left AI
			handle_ai_player_2(delta)  # Right AI
	elif is_ai_enabled:
		# Single player mode - one human, one AI
		if player_side == "left":
			# Human controls Player 1, AI controls Player 2
			handle_human_player_1(delta)
			handle_ai_player_2(delta)
		else:
			# Human controls Player 2, AI controls Player 1
			handle_ai_player_1(delta)
			handle_human_player_2(delta)
	else:
		# Multiplayer mode - both players are human
		handle_human_player_1(delta)
		handle_human_player_2(delta)
````

**Key Features:**

- Dynamic mode switching based on GameState
- Separate AI functions for each player
- Side selection support in single player
- Full AI vs AI automation

```gdscript
func _ready() -> void:
	# Check if AI should be enabled based on GameState
	if has_node("/root/GameState"):
		is_ai_enabled = not GameState.is_multiplayer
		update_ai_parameters()
```

**Explanation:**

- When the game starts, check if we're in single-player mode
- `not GameState.is_multiplayer` means: if NOT multiplayer, then enable AI
- Load AI parameters based on difficulty setting

---

## GameState.gd - AI Difficulty Parameters

### Difficulty-Based Functions

```gdscript
func get_ai_precision() -> float:
	"""Returns precision factor (0.1 to 1.0) based on difficulty"""
	return 0.1 + (ai_difficulty * 0.9)
```

**Explanation:**

- `ai_difficulty` ranges from 0.0 (easy) to 1.0 (perfect)
- **Easy (0%):** 0.1 precision = very inaccurate
- **Perfect (100%):** 1.0 precision = perfect accuracy
- **Medium (50%):** 0.55 precision = decent accuracy

```gdscript
func get_ai_reaction_time() -> float:
	"""Returns reaction time in seconds (0.05 to 0.5) - much more dramatic scaling"""
	return 0.5 - (ai_difficulty * 0.45)
```

**Explanation:**

- **Reaction time** = how long AI takes to respond to ball changes
- **Easy:** 0.5 seconds (very slow, human-like)
- **Perfect:** 0.05 seconds (almost instant)
- **Dramatic scaling** makes difficulty differences very noticeable

```gdscript
func get_ai_prediction_accuracy() -> float:
	"""Returns prediction accuracy (0.3 to 1.0)"""
	return 0.3 + (ai_difficulty * 0.7)

func get_ai_movement_smoothness() -> float:
	"""Returns movement smoothness factor (0.5 to 1.0)"""
	return 0.5 + (ai_difficulty * 0.5)
```

**Explanation:**

- **Prediction accuracy:** How well AI predicts where ball will be
- **Movement smoothness:** How fluid AI movement looks
- Higher difficulty = better prediction + smoother movement

---

## AI State Machine

The AI uses different strategies based on the current game situation:

### States:

1. **TRACKING** - Ball is far away, just follow it
2. **INTERCEPTING** - Ball is approaching, predict and intercept
3. **REPOSITIONING** - Ball moving away, return to good position

### State Transitions

```gdscript
match ai_state:
	"TRACKING":
		if ball_approaching and ball_pos.x > 640:  # Ball past center, approaching
			ai_state = "INTERCEPTING"
	"INTERCEPTING":
		if not ball_approaching or ball_pos.x < 640:  # Ball moving away or back to center
			ai_state = "REPOSITIONING"
	"REPOSITIONING":
		if ball_approaching and ball_pos.x > 640:
			ai_state = "INTERCEPTING"
		elif abs(player_p2.position.y - 360) < 50:  # Close to center
			ai_state = "TRACKING"
```

**Explanation:**

- `ball_approaching = ball_vel.x > 0` - Is ball moving toward Player 2?
- `ball_pos.x > 640` - Is ball past the center line?
- AI switches states based on ball position and direction
- **State machine** ensures AI behaves logically in different situations

---

## AI Movement Logic

### Reaction-Based Updates

```gdscript
# Only update targets when reaction timer allows (based on difficulty)
if ai_reaction_timer >= ai_reaction_time:
	# Calculate target positions based on AI state and difficulty
	var new_target_y = calculate_ai_target_y(ball_pos, ball_vel, ball_approaching, player_p2.position)
	var new_target_x = calculate_ai_target_x(ball_pos, ball_vel, ball_approaching, player_p2.position)

	ai_target_y = new_target_y
	ai_target_x = new_target_x
	ai_reaction_timer = 0.0
```

**Explanation:**

- AI doesn't update its target every frame - only when reaction timer expires
- **Easy AI:** Updates every 0.5 seconds (slow reactions)
- **Perfect AI:** Updates every 0.05 seconds (almost instant)
- This creates realistic human-like delays at lower difficulties

### Vertical Targeting (Y-axis)

```gdscript
func calculate_ai_target_y(ball_pos: Vector2, ball_vel: Vector2, _ball_approaching: bool, player_pos: Vector2) -> float:
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
```

**Explanation:**

- **TRACKING:** Simple ball following, high-difficulty AI predicts deflections
- **INTERCEPTING:** Complex prediction calculation
  - `time_to_reach = distance / speed` - Physics formula for interception
  - `ball_pos.y + ball_vel.y * time` - Where ball will be in the future
  - Only uses positive time (future predictions, not past)

### Horizontal Targeting (X-axis)

```gdscript
func calculate_ai_target_x(ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, player_pos: Vector2) -> float:
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
```

**Explanation:**

- **Low difficulty (0-40%):** No horizontal movement, only up/down
- **Medium difficulty (40-70%):** Conservative horizontal positioning
- **High difficulty (70-100%):** Aggressive forward movement for powerful returns
- **Strategic depth:** Moving forward = hitting ball harder, moving back = defensive

### Error Application

```gdscript
# Apply precision error based on difficulty
if ai_precision < 1.0:
	var error_magnitude = (1.0 - ai_precision) * 100.0
	new_target_y += randf_range(-error_magnitude, error_magnitude)

	# Less horizontal movement error for better gameplay
	var x_error = (1.0 - ai_precision) * 30.0
	new_target_x += randf_range(-x_error, x_error)
```

**Explanation:**

- **Perfect AI (100%):** No error, always accurate
- **Imperfect AI:** Adds random error to targeting
- `randf_range(-error, +error)` - Random error in both directions
- **Vertical error** is larger than horizontal for balanced gameplay
- Makes lower difficulties feel more human and less robotic

---

## AI Movement Execution

### Movement Calculation

```gdscript
# Calculate movement for both axes
var current_pos = player_p2.position
var distance_to_target_y = ai_target_y - current_pos.y
var distance_to_target_x = ai_target_x - current_pos.x
var movement_speed = calculate_ai_movement_speed(distance_to_target_y, ball_approaching)

# Apply movement with smoothness
var move_y = sign(distance_to_target_y) * min(abs(distance_to_target_y) / 50.0, 1.0) * ai_movement_smoothness
var move_x = sign(distance_to_target_x) * min(abs(distance_to_target_x) / 80.0, 0.3) * ai_movement_smoothness

var dir_p2 = Vector2(move_x, move_y).normalized() * Vector2(move_x, move_y).length()
```

**Explanation:**

- `sign()` - Returns -1, 0, or 1 (direction to move)
- `min(distance / 50.0, 1.0)` - Limits movement intensity (0 to 1)
- **Smoothness factor** makes lower difficulties move less fluidly
- `Vector2(x, y).normalized()` - Ensures movement doesn't exceed normal speed
- **Horizontal movement** is limited to 30% intensity for balanced gameplay

### Movement Speed Scaling

```gdscript
func calculate_ai_movement_speed(distance_to_target: float, ball_approaching: bool) -> float:
	var base_speed = 1.0
	var urgency_multiplier = 1.0

	# Increase speed when ball is approaching and AI needs to move
	if ball_approaching and abs(distance_to_target) > 30:
		urgency_multiplier = 1.2 + (ai_precision * 0.3)  # Faster reaction at higher difficulty

	# Reduce speed for lower difficulties (more human-like)
	var difficulty_speed = 0.7 + (ai_precision * 0.3)

	return base_speed * urgency_multiplier * difficulty_speed
```

**Explanation:**

- **Base speed:** Normal movement speed
- **Urgency multiplier:** Moves faster when ball is approaching
- **Difficulty speed:** Lower difficulties move slower overall
- **Combined effect:** Easy AI is slow and sluggish, Perfect AI is fast and responsive

---

## AI Paddle Rotation

### Strategic Angling

```gdscript
func handle_ai_rotation(player: CharacterBody2D, ball_pos: Vector2, ball_vel: Vector2, ball_approaching: bool, delta: float, min_rot: float, max_rot: float):
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
	var ai_rotation_speed = rotation_speed * (0.5 + ai_precision * 0.5)
	player.rotation = lerp_angle(player.rotation, target_rotation, ai_rotation_speed * delta)
```

**Explanation:**

- **Only rotates at medium+ difficulty** (`ai_precision > 0.5`)
- **Strategic angling:** AI tries to aim returns at opponent's weak spots
- **Rotation error:** Lower difficulties have imprecise paddle angling
- **Smooth rotation:** Uses `lerp_angle()` for natural movement
- **Speed scaling:** Higher difficulty rotates paddle faster

### Optimal Return Calculation

```gdscript
func calculate_optimal_return_angle(ball_pos: Vector2, _ball_vel: Vector2) -> float:
	var player1_pos = $"../Player 1".position
	var target_area_y: float

	# Target the area farthest from Player 1
	if player1_pos.y < 360:
		target_area_y = 500  # Aim low if Player 1 is high
	else:
		target_area_y = 220  # Aim high if Player 1 is low

	# Calculate angle needed to reach target area
	var angle_factor = (target_area_y - ball_pos.y) / 200.0
	return clamp(angle_factor, -0.4, 0.4)  # Limit to reasonable angles
```

**Explanation:**

- **Strategic thinking:** AI analyzes opponent's position
- **Target opposite area:** If player is high, AI aims low (and vice versa)
- **Angle calculation:** Simple math to determine paddle angle
- **Clamped angles:** Prevents unrealistic paddle rotations
- **Makes AI feel intelligent** by targeting player's weak spots

---

## Difficulty Progression

### Easy AI (0-30%):

- **Reaction time:** 0.5-0.35 seconds (very slow)
- **Precision:** 10-37% (very inaccurate)
- **Movement:** Vertical only, sluggish
- **Strategy:** Basic ball following, no rotation
- **Feels like:** Beginner human player

### Medium AI (30-70%):

- **Reaction time:** 0.35-0.2 seconds (moderate)
- **Precision:** 37-73% (decent accuracy)
- **Movement:** Some horizontal movement, smoother
- **Strategy:** Basic prediction, some paddle rotation
- **Feels like:** Intermediate human player

### Hard AI (70-100%):

- **Reaction time:** 0.2-0.05 seconds (very fast)
- **Precision:** 73-100% (high accuracy)
- **Movement:** Full 2D movement, aggressive positioning
- **Strategy:** Advanced prediction, strategic returns, targeting weak spots
- **Feels like:** Expert human player

---

## Integration with Game Systems

### GameState Communication

```gdscript
# In main_menu.gd - Setting AI difficulty
GameState.ai_difficulty = settings_scene_instance.ai_difficulty

# In player_1.gd - Using AI difficulty
ai_precision = GameState.get_ai_precision()
ai_reaction_time = GameState.get_ai_reaction_time()
```

**Explanation:**

- **GameState** acts as a bridge between different parts of the game
- Settings panel → GameState → AI system
- **Centralized difficulty management** ensures consistency

### Ball Interaction

```gdscript
# AI gets ball reference to track movement
ball_node = get_parent().get_node_or_null("Ball")

# AI reads ball position and velocity for predictions
var ball_pos = ball_node.position
var ball_vel = ball_node.linear_velocity
```

**Explanation:**

- AI needs real-time ball data for intelligent decisions
- **Position:** Where the ball is now
- **Velocity:** Where the ball is going
- **Safe access:** Uses `get_node_or_null()` to prevent crashes

---

## Common AI Patterns

### 1. **State-Based Behavior**

```gdscript
match ai_state:
	"STATE_1":
		# Behavior for state 1
	"STATE_2":
		# Behavior for state 2
```

- Different behaviors for different situations
- Makes AI feel more intelligent and responsive

### 2. **Difficulty-Gated Features**

```gdscript
if ai_precision > 0.5:
	# Advanced behavior only for higher difficulties
```

- New features unlock as difficulty increases
- Creates clear progression from easy to hard

### 3. **Error Application**

```gdscript
if ai_precision < 1.0:
	target += randf_range(-error, error)
```

- Perfect AI would be unfun to play against
- Random errors make AI feel more human

### 4. **Smooth Transitions**

```gdscript
current_value = lerp(current_value, target_value, speed * delta)
```

- Prevents jerky, robotic movement
- Makes AI feel more natural and polished

This AI system creates engaging single-player gameplay that scales smoothly from beginner-friendly to extremely challenging, while maintaining realistic and human-like behavior patterns.
