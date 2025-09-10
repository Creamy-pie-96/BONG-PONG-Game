extends RigidBody2D

# Default constants - will be overridden by settings
var MIN_BALL_SPEED = 600
var MAX_BALL_SPEED = 1200
const MAX_Y_SPEED = 720
const MOMENTUM_DAMPING = 0.8

var Player1_point: int = 0
var Player2_point: int = 0
var is_right_side : bool = true

func _ready() -> void:
	# Load settings and apply them
	load_and_apply_settings()
	
	# Get dynamic screen center
	var viewport = get_viewport()
	var screen_center = Vector2(viewport.get_visible_rect().size.x / 2.0, viewport.get_visible_rect().size.y / 2.0)
	position = screen_center
	
	linear_damp = 0.08
	angular_damp = 0.0
	
	var rand_gen := RandomNumberGenerator.new()
	rand_gen.randomize()
	is_right_side = rand_gen.randi_range(0,1)
	
	if is_right_side:
		linear_velocity = Vector2(MIN_BALL_SPEED, 0)
	elif !is_right_side:
		linear_velocity = Vector2(-MIN_BALL_SPEED, 0)
	
	print(is_right_side)
	update_score_labels()
	
	# Configure timer but don't start it yet
	$Timer.one_shot = true
	$Timer.autostart = false
	$Timer.wait_time = 2.0
	# Connect the timeout signal if not already connected in editor
	if not $Timer.timeout.is_connected(_on_timer_timeout):
		$Timer.timeout.connect(_on_timer_timeout)

func load_and_apply_settings():
	"""Load settings and apply ball speed and gravity"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	var ball_speed_percent = 0.5  # Default 50% (100% displayed)
	var gravity_percent = 0.5     # Default 50% (0 gravity)
	
	if err == OK:
		ball_speed_percent = config.get_value("gameplay", "ball_speed", 0.5)
		gravity_percent = config.get_value("gameplay", "gravity", 0.5)
	
	# Calculate ball speeds: 0% = 600, 100% = 900
	MIN_BALL_SPEED = int(lerp(600, 900, ball_speed_percent))
	MAX_BALL_SPEED = MIN_BALL_SPEED + 600
	
	# Calculate gravity with proper Earth values: 50% = 0, 100% = +9.8, 0% = -9.8
	# In Godot, default gravity is approximately 9.8 m/s² (Earth gravity)
	if gravity_percent == 0.5:
		gravity_scale = 0.0  # No gravity at 50%
	elif gravity_percent > 0.5:
		# 50% to 100% maps to 0 to +9.8 (normal Earth gravity)
		gravity_scale = lerp(0.0, 9.8, (gravity_percent - 0.5) / 0.5)
	else:
		# 0% to 50% maps to -9.8 to 0 (reverse Earth gravity)
		gravity_scale = lerp(-9.8, 0.0, gravity_percent / 0.5)
	
	# Calculate bounce factor based on gravity: more gravity = more bounce
	# When gravity is 0 (50%), bounce is 1.0 (normal)
	# As gravity increases, bounce multiplier increases
	var gravity_abs = abs(gravity_scale)
	var bounce_multiplier = 1.0 + (gravity_abs / 9.8) * 2.0  # Max 3x bounce at max Earth gravity
	physics_material_override.bounce = bounce_multiplier
	
	print("Ball settings applied - MIN_SPEED: ", MIN_BALL_SPEED, " MAX_SPEED: ", MAX_BALL_SPEED, " Gravity: ", gravity_scale, " Bounce: ", bounce_multiplier)

func _reset_ball() -> void:
	# Stop all physics temporarily
	set_deferred("freeze", true)
	
	# Reset all physics properties
	set_deferred("position", Vector2(640, 360))
	set_deferred("linear_velocity", Vector2.ZERO)  # Start with zero velocity
	set_deferred("angular_velocity", 0.0)
	set_deferred("rotation", 0.0)
	_reset_player()
	# Start the timer to delay ball launch
	$Timer.start()
	
	update_score_labels()

func _unfreeze_ball() -> void:
	# Set the velocity based on which side should serve
	if is_right_side:
		linear_velocity = Vector2(MIN_BALL_SPEED, 0)
	else:
		linear_velocity = Vector2(-MIN_BALL_SPEED, 0)
	
	# Unfreeze the ball
	freeze = false


func _physics_process(_delta: float) -> void:
	# Clamp velocity components to avoid vertical/horizontal extremes
	if linear_velocity.x > 0:
		linear_velocity.x = clamp(linear_velocity.x, MIN_BALL_SPEED, MAX_BALL_SPEED)
	else:
		linear_velocity.x = clamp(linear_velocity.x, -MAX_BALL_SPEED, -MIN_BALL_SPEED)

	linear_velocity.y = clamp(linear_velocity.y, -MAX_Y_SPEED * 0.6, MAX_Y_SPEED * 0.6)

	# Maintain total speed
	linear_velocity = linear_velocity.normalized() * linear_velocity.length()


func _on_area_2d_body_entered(body) -> void:
	# Only respond when a player (CharacterBody2D) touches the trigger.
	# The Area2D signal can pass various PhysicsBody types, so avoid
	# a strict typed parameter to prevent conversion errors at runtime.
	if not (body is CharacterBody2D):
		return

	$"../BallSound".play()

	# Ignore some edge cases where the player's velocity would cause
	# an incorrect collision reading at the screen edges.
	if (body.position.x >= 1208.0 and body.velocity.x > 0) or (body.position.x <= 72.0 and body.velocity.x < 0):
		return # this return happens so the collision dont be bugged

	# Apply momentum from the player (player script exposes `mass` and `velocity`).
	linear_velocity += ((body.velocity * body.mass) / mass) * MOMENTUM_DAMPING

	# Clamp after momentum
	if linear_velocity.x > 0:
		linear_velocity.x = clamp(linear_velocity.x, MIN_BALL_SPEED, MAX_BALL_SPEED)
	else:
		linear_velocity.x = clamp(linear_velocity.x, -MAX_BALL_SPEED, -MIN_BALL_SPEED)

	linear_velocity.y = clamp(linear_velocity.y, -MAX_Y_SPEED * 0.6, MAX_Y_SPEED * 0.6)

	# Normalize total speed
	linear_velocity = linear_velocity.normalized() * linear_velocity.length()
	print("Ball velocity: ", linear_velocity)

func _on_area_2d_area_entered(area: Area2D) -> void:
	$"../Score".play()
	if area.name == "Goal area player 2 side":
		Player1_point += 1
	elif area.name == "Goal area player 1 side":
		Player2_point += 1
	is_right_side = !is_right_side
	print(is_right_side)
	_reset_ball()

func update_score_labels():
	get_node("../CanvasLayer/Player 1 point").text = str(Player1_point)
	get_node("../CanvasLayer/Player 2 point").text = str(Player2_point)


func _on_timer_timeout() -> void:
	# Launch the ball after the delay
	_unfreeze_ball()
	print("Ball launched towards: ", "right" if is_right_side else "left")

func _reset_player() -> void:
	# Get dynamic positions
	var viewport = get_viewport()
	var screen_width = viewport.get_visible_rect().size.x
	var screen_center_y = viewport.get_visible_rect().size.y / 2.0
	var player_x_offset = 72.0
	
	# Reset Player 1 (left side)
	$"../Player 1".position = Vector2(player_x_offset, screen_center_y)
	$"../Player 1".rotation = 0.0
	$"../Player 1".velocity = Vector2.ZERO
	
	# Reset Player 2 (right side)
	$"../Player 2".position = Vector2(screen_width - player_x_offset, screen_center_y)
	$"../Player 2".rotation = 0.0
	$"../Player 2".velocity = Vector2.ZERO
