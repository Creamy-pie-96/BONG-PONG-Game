extends Node2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var tween = create_tween()

func _ready():
	# Example 1: Simple animation playback
	animated_sprite.play("idle")
	
	# Example 2: Tween animation (smooth movement)
	tween_ball_to_position(Vector2(100, 100))

func tween_ball_to_position(target_position):
	# Create a smooth animation to move to target
	var tween = create_tween()
	tween.tween_property($Ball, "position", target_position, 1.0)
	tween.tween_callback(func(): print("Animation finished!"))

func _input(event):
	if event.is_action_pressed("ui_accept"):
		# Play a different animation
		animated_sprite.play("jump")
		
		# Or create a bounce effect
		var bounce_tween = create_tween()
		bounce_tween.tween_property($Ball, "scale", Vector2(1.2, 0.8), 0.1)
		bounce_tween.tween_property($Ball, "scale", Vector2(1.0, 1.0), 0.1)
