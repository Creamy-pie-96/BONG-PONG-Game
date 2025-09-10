# Settings System Explanation

This document explains how the settings system works in your Pong game, with line-by-line code explanations.

## Overview

The settings system allows players to customize:

- Background music (on/off + volume)
- Sound effects volume
- Ball speed
- Gravity
- AI difficulty (for single-player mode)

All settings are saved to a file and persist between game sessions.

## File Structure

### Main Files:

- `settings.tscn` - The visual settings panel UI
- `settings.gd` - The logic that handles settings
- `main_menu.gd` - Connects settings to the main menu
- `user://settings.cfg` - Where settings are saved

---

## settings.gd - Line by Line Explanation

### Class Declaration and Signals

```gdscript
extends Node2D

signal music_toggled(enabled: bool)
signal music_volume_changed(volume: float)
signal sfx_volume_changed(volume: float)
signal ball_speed_changed(speed: float)
signal gravity_changed(gravity: float)
signal ai_difficulty_changed(difficulty: float)
```

**Explanation:**

- `extends Node2D` - This script attaches to a 2D node
- `signal` - These are events that other scripts can "listen" to
- When a setting changes, we emit (send) a signal to notify other parts of the game

### Variables to Store Settings

```gdscript
var back_music_on : bool = true
var music_volume : float = 0.5  # Default to 50%
var sfx_volume : float = 0.5    # Default to 50%
var ball_speed : float = 1.0    # Default 100% (900 speed)
var gravity : float = 0.5       # Default 50% (0 gravity)
var ai_difficulty : float = 0.5  # Default 50% (medium difficulty)
```

**Explanation:**

- These variables store the current values of all settings
- `bool` = true/false value for music on/off
- `float` = decimal number (0.0 to 1.0) representing percentage
- Default values are what the game uses if no saved settings exist

### Initialization

```gdscript
func _ready():
	# Load settings FIRST before setting UI elements
	load_setting()

	# THEN set UI elements to match loaded values
	update_ui_from_settings()
```

**Explanation:**

- `_ready()` runs automatically when the scene starts
- **Step 1:** Load any saved settings from disk
- **Step 2:** Update the UI sliders/buttons to show the loaded values
- **Order matters!** We must load before updating UI

### Loading Settings from File

```gdscript
func load_setting():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		back_music_on = config.get_value("audio", "music_enabled", true)
		music_volume = config.get_value("audio", "music_volume", 0.5)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.5)
		ball_speed = config.get_value("gameplay", "ball_speed", 0.5)
		gravity = config.get_value("gameplay", "gravity", 0.5)
		ai_difficulty = config.get_value("gameplay", "ai_difficulty", 0.5)
	else:
		# If no config file exists, use defaults
		back_music_on = true
		music_volume = 0.5
		sfx_volume = 0.5
		ball_speed = 0.5
		gravity = 0.5
		ai_difficulty = 0.5
```

**Explanation:**

- `ConfigFile.new()` - Creates a new file reader/writer
- `config.load("user://settings.cfg")` - Tries to load the settings file
- `user://` - Special folder where Godot saves user data
- `err == OK` - Check if file loaded successfully
- `config.get_value("section", "key", default)` - Gets a value from the file
  - If the value doesn't exist, uses the default instead
- **Sections organize related settings:**
  - `"audio"` section: music and sound settings
  - `"gameplay"` section: game behavior settings

### Updating UI Elements

```gdscript
func update_ui_from_settings():
	"""Update all UI elements to match current setting values"""
	$CheckButton.button_pressed = back_music_on
	$HSlider.value = music_volume      # Music volume slider
	$HSlider3.value = sfx_volume       # SFX volume slider
	$HSlider2.value = ball_speed       # Ball speed slider
	$HSlider4.value = gravity          # Gravity slider
	if get_node_or_null("AiDifficultiHSlider"):
		$AiDifficultiHSlider.value = ai_difficulty    # AI difficulty slider

	# Update percentage displays
	update_percentage_display("MusicVolumePercent", music_volume)
	update_percentage_display("SFXVolumePercent", sfx_volume)
	update_percentage_display("BallSpeedPercent", ball_speed)
	update_percentage_display("GravityPercent", gravity)
	update_percentage_display("AiDifficultyPercent", ai_difficulty)
```

**Explanation:**

- `$NodeName` - Gets a child node by name ($ is shorthand for get_node())
- `.button_pressed = value` - Sets the checkbox state
- `.value = value` - Sets the slider position
- `get_node_or_null()` - Safe way to get a node (returns null if not found)
- Each UI element is updated to match the loaded setting values
- Percentage displays show human-readable percentages next to sliders

### Percentage Display Function

```gdscript
func update_percentage_display(label_name: String, value: float):
	"""Update percentage label with current value"""
	var label = get_node_or_null(label_name)
	if label:
		var percentage: int

		# Special handling for ball speed (50% to 150% range)
		if label_name == "BallSpeedPercent":
			# Map 0.0-1.0 to 50%-150%
			percentage = int(round(50 + (value * 100)))
		else:
			# Normal 0% to 100% range
			percentage = int(round(value * 100))

		label.text = str(percentage) + "%"
```

**Explanation:**

- Takes a label name and a value (0.0 to 1.0)
- `get_node_or_null()` - Safely gets the label (might not exist)
- **Ball speed is special:** Shows 50%-150% instead of 0%-100%
  - This makes more sense to players (100% = normal speed)
- **Other settings:** Show normal 0%-100%
- `int(round())` - Converts to whole number percentage
- `str() + "%"` - Converts number to text and adds % sign

### Volume Calculation Functions

```gdscript
func calculate_music_volume_db(volume_percent: float, is_game_scene: bool = false) -> float:
	"""
	Calculate dB value based on volume percentage
	50% = 0dB (menu), -5dB (game)
	100% = +10dB (menu), 0dB (game)
	0% = -80dB (muted)
	"""
	if volume_percent <= 0.0:
		return -80.0  # Muted

	if is_game_scene:
		# Game scene: 50% = -5dB, 100% = 0dB
		return lerp(-5.0, 0.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, -5.0, volume_percent / 0.5)
	else:
		# Menu scene: 50% = 0dB, 100% = +10dB
		return lerp(0.0, 10.0, (volume_percent - 0.5) / 0.5) if volume_percent >= 0.5 else lerp(-80.0, 0.0, volume_percent / 0.5)
```

**Explanation:**

- **dB (decibels)** - How Godot measures audio volume
- **Different volume for menu vs game** - Game is quieter so sound effects are heard
- `lerp(a, b, t)` - Linear interpolation (smooth transition between two values)
- **Volume ranges:**
  - 0% = -80dB (effectively muted)
  - 50% = 0dB (menu) or -5dB (game) - comfortable listening
  - 100% = +10dB (menu) or 0dB (game) - maximum volume

### Setting Change Handlers

```gdscript
func _on_check_button_toggled(toggled_on: bool) -> void:
	back_music_on = toggled_on
	emit_signal("music_toggled", back_music_on)
	save_setting()

func _on_music_volume_changed(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	emit_signal("music_volume_changed", music_volume)
	update_percentage_display("MusicVolumePercent", music_volume)
	save_setting()
```

**Explanation:**

- These functions run when UI elements change
- `clamp(value, min, max)` - Ensures value stays within valid range
- `emit_signal()` - Sends a message to other scripts that something changed
- `update_percentage_display()` - Updates the % label immediately
- `save_setting()` - Saves the new value to disk

### Saving Settings

```gdscript
func save_setting():
	var config = ConfigFile.new()
	config.set_value("audio", "music_enabled", back_music_on)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("gameplay", "ball_speed", ball_speed)
	config.set_value("gameplay", "gravity", gravity)
	config.set_value("gameplay", "ai_difficulty", ai_difficulty)
	config.save("user://settings.cfg")
```

**Explanation:**

- Creates a new config file in memory
- `set_value(section, key, value)` - Stores each setting
- `config.save()` - Writes the file to disk
- **Runs every time a setting changes** - No "Save" button needed!

---

## How Settings Connect to Gameplay

### Main Menu Integration

In `main_menu.gd`, the settings are loaded and applied:

```gdscript
# Connect to settings changes
settings_scene_instance.music_volume_changed.connect(_on_music_volume_changed)
settings_scene_instance.ai_difficulty_changed.connect(_on_ai_difficulty_changed)
```

- The main menu "listens" for setting changes
- When settings change, it immediately updates audio levels
- AI difficulty is stored in GameState for the game to use

### Ball Physics Integration

In `ball.gd`, settings affect gameplay:

```gdscript
func load_and_apply_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")

	ball_speed_percent = config.get_value("gameplay", "ball_speed", 0.5)
	gravity_percent = config.get_value("gameplay", "gravity", 0.5)

	# Apply to ball physics
	MIN_BALL_SPEED = int(lerp(600, 900, ball_speed_percent))
	gravity_scale = lerp(-9.81, 9.81, gravity_percent)
```

- Ball loads its own settings when the game starts
- Ball speed and gravity directly affect physics
- Settings create different gameplay experiences

---

## Common Patterns in the Code

### 1. **Load → Update UI → Handle Changes → Save**

```gdscript
# 1. Load
func _ready():
	load_setting()        # Load from disk
	update_ui_from_settings()  # Show in UI

# 2. Handle changes
func _on_setting_changed(value):
	setting_variable = value   # Store new value
	emit_signal("setting_changed", value)  # Notify others
	save_setting()            # Save to disk
```

### 2. **Safe Node Access**

```gdscript
if get_node_or_null("NodeName"):
	$NodeName.value = setting_value
```

- Always check if a node exists before using it
- Prevents crashes if UI elements are missing

### 3. **Value Clamping**

```gdscript
setting_value = clamp(input_value, 0.0, 1.0)
```

- Ensures values stay within valid ranges
- Prevents invalid settings from breaking the game

This settings system provides a robust, user-friendly way to customize the game experience while maintaining data persistence across sessions.
