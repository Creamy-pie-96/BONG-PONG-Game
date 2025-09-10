extends Node2D

# Dictionary to store current key bindings
var key_bindings = {
	"Up__player1": KEY_W,
	"Down__player1": KEY_S,
	"Left__player1": KEY_A,
	"Right__player1": KEY_D,
	"Rotate_anticlockwise__player1": KEY_Q,
	"Rotate_clockwise__player1": KEY_E,
	"Up_player2": KEY_KP_8,
	"Down_player2": KEY_KP_2,
	"Left_player2": KEY_KP_4,
	"Right_player2": KEY_KP_6,
	"Rotate_anticlockwise__player2": KEY_KP_7,
	"Rotate_clockwise__player2": KEY_KP_9
}

# Default key bindings for reset functionality
var default_key_bindings = {
	"Up__player1": KEY_W,
	"Down__player1": KEY_S,
	"Left__player1": KEY_A,
	"Right__player1": KEY_D,
	"Rotate_anticlockwise__player1": KEY_Q,
	"Rotate_clockwise__player1": KEY_E,
	"Up_player2": KEY_KP_8,
	"Down_player2": KEY_KP_2,
	"Left_player2": KEY_KP_4,
	"Right_player2": KEY_KP_6,
	"Rotate_anticlockwise__player2": KEY_KP_7,
	"Rotate_clockwise__player2": KEY_KP_9
}

# Track which button is currently being rebound
var current_rebinding_action = ""
var current_rebinding_button = null
var is_waiting_for_key = false

# Button sound effect
var button_sound: AudioStreamPlayer

func _ready():
	# Create button sound effect
	setup_button_sound()
	
	load_controls()
	update_button_displays()
	connect_button_signals()

func setup_button_sound():
	"""Create and configure button sound effect"""
	button_sound = AudioStreamPlayer.new()
	# You can set a sound file here if you have one
	# button_sound.stream = preload("res://Audio/button_click.wav")
	add_child(button_sound)
	
	# Load volume from settings
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		var sfx_volume = config.get_value("audio", "sfx_volume", 0.5)
		button_sound.volume_db = lerp(-80.0, 0.0, sfx_volume)
	else:
		button_sound.volume_db = lerp(-80.0, 0.0, 0.5)  # Default 50%

func play_button_sound():
	"""Play button click sound if available"""
	if button_sound and button_sound.stream:
		button_sound.play()

func connect_button_signals():
	"""Connect all the key binding buttons to their respective handlers"""
	# Player 1 controls
	$PlayerLabels/Player1Controls/MoveUpP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Up__player1", $PlayerLabels/Player1Controls/MoveUpP1/KeyButton))
	$PlayerLabels/Player1Controls/MoveDownP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Down__player1", $PlayerLabels/Player1Controls/MoveDownP1/KeyButton))
	$PlayerLabels/Player1Controls/MoveLeftP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Left__player1", $PlayerLabels/Player1Controls/MoveLeftP1/KeyButton))
	$PlayerLabels/Player1Controls/MoveRightP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Right__player1", $PlayerLabels/Player1Controls/MoveRightP1/KeyButton))
	$PlayerLabels/Player1Controls/RotateLeftP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Rotate_anticlockwise__player1", $PlayerLabels/Player1Controls/RotateLeftP1/KeyButton))
	$PlayerLabels/Player1Controls/RotateRightP1/KeyButton.pressed.connect(_on_key_button_pressed.bind("Rotate_clockwise__player1", $PlayerLabels/Player1Controls/RotateRightP1/KeyButton))
	
	# Player 2 controls
	$Player2Labels/Player2Controls/MoveUpP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Up_player2", $Player2Labels/Player2Controls/MoveUpP2/KeyButton))
	$Player2Labels/Player2Controls/MoveDownP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Down_player2", $Player2Labels/Player2Controls/MoveDownP2/KeyButton))
	$Player2Labels/Player2Controls/MoveLeftP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Left_player2", $Player2Labels/Player2Controls/MoveLeftP2/KeyButton))
	$Player2Labels/Player2Controls/MoveRightP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Right_player2", $Player2Labels/Player2Controls/MoveRightP2/KeyButton))
	$Player2Labels/Player2Controls/RotateLeftP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Rotate_anticlockwise__player2", $Player2Labels/Player2Controls/RotateLeftP2/KeyButton))
	$Player2Labels/Player2Controls/RotateRightP2/KeyButton.pressed.connect(_on_key_button_pressed.bind("Rotate_clockwise__player2", $Player2Labels/Player2Controls/RotateRightP2/KeyButton))
	
	# Bottom buttons
	$BottomButtons/ResetButton.pressed.connect(_on_reset_button_pressed)
	$BottomButtons/BackButton.pressed.connect(_on_back_button_pressed)

func _on_key_button_pressed(action_name: String, button: Button):
	"""Start the key rebinding process for the specified action"""
	play_button_sound()
	
	if is_waiting_for_key:
		return  # Prevent multiple rebinding attempts
	
	current_rebinding_action = action_name
	current_rebinding_button = button
	is_waiting_for_key = true
	
	# Update button text to show waiting state
	button.text = "Press Key..."
	button.modulate = Color.YELLOW
	
	# Show waiting dialog
	$WaitingDialog.popup_centered()

func _input(event):
	"""Handle key input for rebinding and general controls"""
	# Only handle input if controls scene is visible
	if not visible:
		return
	
	if event is InputEventKey and event.pressed:
		# If we're waiting for key rebinding
		if is_waiting_for_key:
			# Cancel rebinding if ESC is pressed
			if event.keycode == KEY_ESCAPE:
				_cancel_rebinding()
				get_viewport().set_input_as_handled()
				return
			
			# Check if this key is already bound to another action
			var existing_action = _find_action_with_key(event.keycode)
			if existing_action != "" and existing_action != current_rebinding_action:
				_show_key_conflict_dialog(existing_action, event.keycode)
				get_viewport().set_input_as_handled()
				return
			
			# Bind the new key
			_complete_rebinding(event.keycode)
			get_viewport().set_input_as_handled()
		else:
			# If not rebinding, ESC should go back to settings
			if event.keycode == KEY_ESCAPE:
				_on_back_button_pressed()
				get_viewport().set_input_as_handled()

func _find_action_with_key(keycode: int) -> String:
	"""Find which action (if any) currently uses this keycode"""
	for action in key_bindings:
		if key_bindings[action] == keycode:
			return action
	return ""

func _show_key_conflict_dialog(existing_action: String, keycode: int):
	"""Show dialog when user tries to bind a key that's already in use"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "Key Already Bound"
	dialog.dialog_text = "The key '" + OS.get_keycode_string(keycode) + "' is already bound to '" + _get_friendly_action_name(existing_action) + "'.\n\nDo you want to replace it?"
	add_child(dialog)
	dialog.popup_centered()
	
	# Connect the confirmed signal
	dialog.confirmed.connect(_on_conflict_confirmed.bind(keycode, dialog))
	dialog.canceled.connect(_cancel_rebinding)

func _on_conflict_confirmed(keycode: int, dialog: ConfirmationDialog):
	"""Handle confirmed key conflict replacement"""
	dialog.queue_free()
	_complete_rebinding(keycode)

func _complete_rebinding(keycode: int):
	"""Complete the key rebinding process"""
	# Clear any existing binding of this key
	for action in key_bindings:
		if key_bindings[action] == keycode:
			key_bindings[action] = KEY_NONE  # Temporarily unbind
	
	# Bind the new key
	key_bindings[current_rebinding_action] = keycode
	
	# Update the input map
	_update_input_map()
	
	# Update button displays
	update_button_displays()
	
	# Save the new bindings
	save_controls()
	
	# Reset rebinding state
	_cancel_rebinding()

func _cancel_rebinding():
	"""Cancel the current rebinding operation"""
	if current_rebinding_button:
		current_rebinding_button.modulate = Color.WHITE
	
	current_rebinding_action = ""
	current_rebinding_button = null
	is_waiting_for_key = false
	
	# Close waiting dialog
	if $WaitingDialog.visible:
		$WaitingDialog.hide()
	
	# Update button displays to restore original text
	update_button_displays()

func _update_input_map():
	"""Update Godot's input map with current key bindings"""
	for action in key_bindings:
		# Clear existing events for this action
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			InputMap.add_action(action)
		
		# Add the new key event
		if key_bindings[action] != KEY_NONE:
			var event = InputEventKey.new()
			event.keycode = key_bindings[action]
			InputMap.action_add_event(action, event)

func update_button_displays():
	"""Update all button text to show current key bindings"""
	# Player 1
	$PlayerLabels/Player1Controls/MoveUpP1/KeyButton.text = OS.get_keycode_string(key_bindings["Up__player1"])
	$PlayerLabels/Player1Controls/MoveDownP1/KeyButton.text = OS.get_keycode_string(key_bindings["Down__player1"])
	$PlayerLabels/Player1Controls/MoveLeftP1/KeyButton.text = OS.get_keycode_string(key_bindings["Left__player1"])
	$PlayerLabels/Player1Controls/MoveRightP1/KeyButton.text = OS.get_keycode_string(key_bindings["Right__player1"])
	$PlayerLabels/Player1Controls/RotateLeftP1/KeyButton.text = OS.get_keycode_string(key_bindings["Rotate_anticlockwise__player1"])
	$PlayerLabels/Player1Controls/RotateRightP1/KeyButton.text = OS.get_keycode_string(key_bindings["Rotate_clockwise__player1"])
	
	# Player 2
	$Player2Labels/Player2Controls/MoveUpP2/KeyButton.text = OS.get_keycode_string(key_bindings["Up_player2"])
	$Player2Labels/Player2Controls/MoveDownP2/KeyButton.text = OS.get_keycode_string(key_bindings["Down_player2"])
	$Player2Labels/Player2Controls/MoveLeftP2/KeyButton.text = OS.get_keycode_string(key_bindings["Left_player2"])
	$Player2Labels/Player2Controls/MoveRightP2/KeyButton.text = OS.get_keycode_string(key_bindings["Right_player2"])
	$Player2Labels/Player2Controls/RotateLeftP2/KeyButton.text = OS.get_keycode_string(key_bindings["Rotate_anticlockwise__player2"])
	$Player2Labels/Player2Controls/RotateRightP2/KeyButton.text = OS.get_keycode_string(key_bindings["Rotate_clockwise__player2"])

func _get_friendly_action_name(action: String) -> String:
	"""Convert action name to user-friendly display name"""
	var friendly_names = {
		"Up__player1": "Player 1 Move Up",
		"Down__player1": "Player 1 Move Down",
		"Left__player1": "Player 1 Move Left",
		"Right__player1": "Player 1 Move Right",
		"Rotate_anticlockwise__player1": "Player 1 Rotate Left",
		"Rotate_clockwise__player1": "Player 1 Rotate Right",
		"Up_player2": "Player 2 Move Up",
		"Down_player2": "Player 2 Move Down",
		"Left_player2": "Player 2 Move Left",
		"Right_player2": "Player 2 Move Right",
		"Rotate_anticlockwise__player2": "Player 2 Rotate Left",
		"Rotate_clockwise__player2": "Player 2 Rotate Right"
	}
	return friendly_names.get(action, action)

func _on_reset_button_pressed():
	"""Reset all controls to default values"""
	play_button_sound()
	
	var dialog = ConfirmationDialog.new()
	dialog.title = "Reset Controls"
	dialog.dialog_text = "Are you sure you want to reset all controls to their default values?"
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(_confirm_reset.bind(dialog))

func _confirm_reset(dialog: ConfirmationDialog):
	"""Confirm and execute control reset"""
	dialog.queue_free()
	
	# Reset to default bindings
	key_bindings = default_key_bindings.duplicate()
	
	# Update input map and displays
	_update_input_map()
	update_button_displays()
	
	# Save the reset bindings
	save_controls()

func _on_back_button_pressed():
	"""Return to the settings menu"""
	play_button_sound()
	
	# Find and show the settings panel again
	# The settings scene should be a sibling of this controls scene
	var parent_node = get_parent()
	if parent_node:
		# Look for settings node by checking for specific nodes that settings has
		for child in parent_node.get_children():
			if child.has_method("load_setting") and child.has_method("save_setting"):
				child.show()
				break
	
	# Remove this controls scene
	queue_free()

func save_controls():
	"""Save current control bindings to config file"""
	var config = ConfigFile.new()
	
	# Load existing config to preserve other settings
	config.load("user://settings.cfg")
	
	# Save control bindings
	for action in key_bindings:
		config.set_value("controls", action, key_bindings[action])
	
	config.save("user://settings.cfg")

func load_controls():
	"""Load control bindings from config file"""
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		# Load saved bindings, use defaults for any missing actions
		for action in key_bindings:
			key_bindings[action] = config.get_value("controls", action, default_key_bindings[action])
	else:
		# Use default bindings if no config exists
		key_bindings = default_key_bindings.duplicate()
	
	# Update the input map with loaded bindings
	_update_input_map()
