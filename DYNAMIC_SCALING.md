# Dynamic Window Size and UI Scaling Guide

_An In-Depth Explanation for Complete Beginners_

## What is Dynamic Scaling and Why Do We Need It?

Imagine you're playing a game on your phone, then you switch to your computer, and then to your friend's giant TV. Without dynamic scaling, the game would look completely different on each screen - maybe the ball is too small to see, or the paddles are in the wrong places, or everything is squished together.

**Dynamic scaling** means the game automatically adjusts all its elements to look and work correctly no matter what size screen you're using. It's like having a smart game that knows how to rearrange itself perfectly for any screen.

## The Problem We're Solving

### Without Dynamic Scaling:

```
❌ Game designed for 1280x720 screen
❌ On 1920x1080: Everything looks tiny and spread out
❌ On 800x600: Elements might not even fit on screen
❌ Players positioned at fixed pixel locations
❌ If you resize the window, everything stays in wrong places
```

### With Dynamic Scaling:

```
✅ Game adapts to ANY screen size automatically
✅ Players always positioned correctly relative to screen edges
✅ Ball always spawns in center no matter the screen size
✅ UI elements scale appropriately
✅ Game looks and plays the same on all devices
```

## Core Dynamic Positioning System

### Background Scene (`background.gd`) - The Master Controller

Think of `background.gd` as the "stage manager" of our game. Just like a stage manager positions actors on a theater stage, this script positions all game elements on the screen.

#### The Main Setup Function

```gdscript
func setup_dynamic_positioning():
    """Set up all game elements to scale with window size"""
    var viewport = get_viewport()
    var screen_size = viewport.get_visible_rect().size
    var screen_center_x = screen_size.x / 2
    var screen_center_y = screen_size.y / 2
```

**Line-by-Line Explanation:**

1. **`var viewport = get_viewport()`**

   - **What it does:** Gets information about the current screen/window
   - **Why we need it:** The viewport tells us how big the screen currently is
   - **Real-world analogy:** Like asking "How big is this stage I'm working with?"
   - **If we didn't do this:** We'd have no way to know the screen size

2. **`var screen_size = viewport.get_visible_rect().size`**

   - **What it does:** Gets the exact width and height of the current screen
   - **Why we need it:** We need these numbers to calculate where everything should go
   - **Example:** On a 1920x1080 screen, this gives us Vector2(1920, 1080)
   - **If we didn't do this:** We'd be guessing at screen dimensions

3. **`var screen_center_x = screen_size.x / 2`**

   - **What it does:** Calculates the horizontal center point of the screen
   - **Why we need it:** Many elements (like the ball) need to be centered
   - **Math explanation:** If screen is 1920 pixels wide, center is at 960 pixels
   - **If we didn't do this:** We'd have to hardcode the center, which breaks on different screens

4. **`var screen_center_y = screen_size.y / 2`**
   - **Same logic as above, but for vertical center**
   - **Example:** If screen is 1080 pixels tall, center is at 540 pixels

#### Player Positioning Logic

```gdscript
var player_x_offset = screen_size.x * 0.15  # 15% from edges
$"Player 1".position = Vector2(player_x_offset, screen_center_y)
$"Player 2".position = Vector2(screen_size.x - player_x_offset, screen_center_y)
```

**Line-by-Line Explanation:**

1. **`var player_x_offset = screen_size.x * 0.15`**

   - **What it does:** Calculates how far from the edge to place players
   - **Why 15%:** This looks good on any screen size - not too close to edge, not too far
   - **Math example:** On 1920px screen: 1920 × 0.15 = 288 pixels from edge
   - **Why percentage:** Fixed pixels (like 200) would look terrible on different screens
   - **If we used fixed pixels:** Players would be in wrong positions on different screens

2. **`$"Player 1".position = Vector2(player_x_offset, screen_center_y)`**

   - **What it does:** Places Player 1 at the calculated position
   - **`$"Player 1"`:** This finds the Player 1 object in our game
   - **`.position =`:** This changes where the player is located
   - **`Vector2(x, y)`:** This is how we specify a position with x and y coordinates
   - **Result:** Player 1 is 15% from left edge, centered vertically

3. **`$"Player 2".position = Vector2(screen_size.x - player_x_offset, screen_center_y)`**
   - **What it does:** Places Player 2 on the right side
   - **`screen_size.x - player_x_offset`:** This calculates the right-side position
   - **Math example:** 1920 - 288 = 1632 (15% from right edge)
   - **Why subtract:** We want the same distance from the right edge as Player 1 is from left

#### Border Scaling Logic

```gdscript
var border_thickness = 28
var border_length = screen_size.y + 40  # Extra height for safety
var wall_length = screen_size.x + 40   # Extra width for safety

# Right wall
$Borders/CollisionShape2D.position = Vector2(screen_size.x + border_thickness/2, screen_center_y)
$Borders/CollisionShape2D.shape.size = Vector2(border_thickness, border_length)
```

**Line-by-Line Explanation:**

1. **`var border_thickness = 28`**

   - **What it does:** Sets how thick our invisible walls are
   - **Why 28:** This is thick enough to stop the ball but not too thick
   - **Fixed vs dynamic:** This could be dynamic too, but 28 works well on all screens

2. **`var border_length = screen_size.y + 40`**

   - **What it does:** Makes walls tall enough to cover the entire screen height
   - **Why +40:** Extra height as a safety margin in case of calculation errors
   - **Safety margin concept:** Like making a fence slightly taller than needed

3. **`$Borders/CollisionShape2D.position = Vector2(screen_size.x + border_thickness/2, screen_center_y)`**
   - **What it does:** Positions the right wall just outside the screen
   - **`screen_size.x +`:** This puts it at the right edge of the screen
   - **`+ border_thickness/2`:** Centers the wall thickness on the edge
   - **Why centered:** So half the wall is on-screen (visible) and half off-screen

#### Window Resize Handling

```gdscript
func _ready():
    # ... other setup code ...
    get_viewport().size_changed.connect(_on_window_resized)

func _on_window_resized():
    """Handle window resize by repositioning all elements"""
    setup_dynamic_positioning()
```

**Line-by-Line Explanation:**

1. **`get_viewport().size_changed.connect(_on_window_resized)`**

   - **What it does:** Sets up a "listener" for window resize events
   - **`.size_changed`:** This is an event that fires when window size changes
   - **`.connect()`:** This tells the game "when size changes, call this function"
   - **Real-world analogy:** Like setting an alarm that goes off when something happens
   - **Why we need this:** Without this, resizing window would break the game

2. **`func _on_window_resized():`**

   - **What it does:** This function runs every time the window is resized
   - **Why we need it:** We need to recalculate all positions when screen size changes

3. **`setup_dynamic_positioning()`**
   - **What it does:** Calls our main positioning function again
   - **Why this works:** Recalculating with new screen size fixes all positions
   - **Efficiency:** Only runs when needed (during resize), not every frame

### Ball Physics (`ball.gd`) - Dynamic Ball Behavior

The ball needs to know about screen size so it can:

- Spawn in the center no matter what screen size
- Stay within screen boundaries
- Reset to center correctly

```gdscript
func _ready():
    var viewport = get_viewport()
    var screen_size = viewport.get_visible_rect().size
    screen_center_x = screen_size.x / 2
    screen_center_y = screen_size.y / 2

    # Set initial position to screen center
    position = Vector2(screen_center_x, screen_center_y)
```

**Why the Ball Needs This:**

- **Without dynamic positioning:** Ball might spawn off-screen or in wrong location
- **With dynamic positioning:** Ball always spawns perfectly centered
- **When screen resizes:** Ball position updates automatically

### Player Logic (`player_1.gd`) - Smart AI and Movement

The player/AI code needs screen awareness for:

- Movement boundaries (don't go off-screen)
- AI targeting calculations
- Working correctly on both left and right sides

```gdscript
func _ready():
    var viewport_size = get_viewport().get_visible_rect().size
    var boundary_margin = viewport_size.y * 0.1  # 10% margin from top/bottom
    top_boundary = boundary_margin
    bottom_boundary = viewport_size.y - boundary_margin
```

**Line-by-Line Explanation:**

1. **`var boundary_margin = viewport_size.y * 0.1`**

   - **What it does:** Calculates a 10% margin from screen edges
   - **Why 10%:** Keeps players from getting too close to screen edges
   - **Example:** On 1080px tall screen: 1080 × 0.1 = 108 pixel margin
   - **Why percentage:** Works proportionally on any screen size

2. **`top_boundary = boundary_margin`**

   - **What it does:** Sets the highest point players can move to
   - **Why needed:** Prevents players from going off the top of the screen

3. **`bottom_boundary = viewport_size.y - boundary_margin`**
   - **What it does:** Sets the lowest point players can move to
   - **Math:** Total height minus margin gives us the bottom limit
   - **Example:** 1080 - 108 = 972 (bottom boundary)

## UI Scaling Strategy

### CanvasLayer Elements - Automatic Scaling

```gdscript
# In background.tscn, score labels are inside a CanvasLayer
[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="Player 1 point" type="Label" parent="CanvasLayer"]
anchors_preset = -1
anchor_left = 0.03    # 3% from left edge
anchor_top = 0.029    # 2.9% from top edge
```

**Why CanvasLayer is Special:**

- **CanvasLayer:** A special container that automatically handles UI scaling
- **Anchors:** Instead of fixed positions, we use percentages of screen size
- **`anchor_left = 0.03`:** Always 3% from left edge, regardless of screen size
- **Automatic scaling:** Font sizes and UI elements scale with screen size

**Without CanvasLayer and Anchors:**

```
❌ Score label always at position (50, 50)
❌ On small screen: Takes up huge portion of screen
❌ On large screen: Tiny and hard to see
❌ Wrong position on different screen sizes
```

**With CanvasLayer and Anchors:**

```
✅ Score label always at 3% from edge
✅ Scales appropriately on all screen sizes
✅ Always readable and well-positioned
✅ Automatic font scaling
```

## Testing Different Screen Sizes

### Why We Test Multiple Sizes:

1. **Minimum Resolution (800x600):** Ensure everything fits on small screens
2. **Standard HD (1920x1080):** Most common desktop resolution
3. **Ultrawide (2560x1080):** Very wide screens need special consideration
4. **Mobile Landscape (1280x720):** Tablet and mobile device sizes

### Validation Checklist:

```
□ Players positioned correctly at screen edges (15% from sides)
□ Ball spawns and moves within screen bounds
□ Goal areas positioned at screen edges (0% and 100% width)
□ UI elements visible and properly scaled
□ AI logic works correctly for all screen sizes
□ Window resize updates all elements immediately
□ No elements go off-screen or overlap incorrectly
```

## Performance Considerations

### Efficient Updates

```gdscript
func _on_window_resized():
    setup_dynamic_positioning()  # Only repositions, doesn't recreate
```

**Why This is Efficient:**

- **No recreation:** We don't delete and recreate objects
- **Only positioning:** We just change where things are located
- **Infrequent calls:** Window resize doesn't happen often
- **Single function:** One function handles all repositioning

**What We DON'T Do (inefficient):**

```gdscript
# ❌ BAD - This would be wasteful
func _process(delta):
    setup_dynamic_positioning()  # Don't do this every frame!
```

## Real-World Benefits

### For Players:

- **Consistency:** Game looks and feels the same on any device
- **Accessibility:** Works on phones, tablets, laptops, desktops, TVs
- **Flexibility:** Can resize window to their preference
- **Professional feel:** Game adapts intelligently to their setup

### For Developers:

- **Future-proof:** Works on devices that don't exist yet
- **Less testing:** Don't need to test every possible screen size
- **Maintainable:** One system handles all scaling
- **Professional quality:** Shows understanding of good game design

This dynamic scaling system ensures our Pong game provides a consistent, professional experience regardless of the player's screen size or device, making it truly universal and accessible.

````

### Player Positioning Formula

```gdscript
var player_x_offset = screen_size.x * 0.15  # 15% from edges
$"Player 1".position = Vector2(player_x_offset, screen_center_y)
$"Player 2".position = Vector2(screen_size.x - player_x_offset, screen_center_y)
````

### Border Scaling

```gdscript
# Borders scale to screen dimensions with safety margins
var border_length = screen_size.y + 40  # Extra height for safety
var wall_length = screen_size.x + 40   # Extra width for safety
```

### AI Boundary Calculations

```gdscript
# AI boundaries are percentage-based for any screen size
var boundary_margin = viewport_size.y * 0.1  # 10% margin from top/bottom
var top_boundary = boundary_margin
var bottom_boundary = viewport_size.y - boundary_margin
```

## Window Resize Handling

### Automatic Repositioning

- **Signal Connection**: `get_viewport().size_changed.connect(_on_window_resized)`
- **Refresh Function**: `_on_window_resized()` calls `setup_dynamic_positioning()`
- **Real-Time Updates**: All elements reposition immediately when window resizes

### Performance Considerations

- **Efficient Updates**: Only repositions elements, doesn't recreate them
- **Single Function**: `setup_dynamic_positioning()` handles all elements
- **Minimal Overhead**: Resize events are infrequent and handling is lightweight

## Testing Different Screen Sizes

### Recommended Test Scenarios

1. **Minimum Resolution**: 800x600 (ensure all elements fit)
2. **Standard HD**: 1920x1080 (typical desktop)
3. **Ultrawide**: 2560x1080 (wide aspect ratio)
4. **Mobile Landscape**: 1280x720 (mobile devices)
5. **Custom Sizes**: Various window sizes via dragging

### Validation Checklist

- [ ] Players positioned correctly at screen edges
- [ ] Ball spawns and moves within screen bounds
- [ ] Goal areas positioned at screen edges
- [ ] UI elements visible and properly scaled
- [ ] AI logic works correctly for all screen sizes
- [ ] Window resize updates all elements immediately

## Future Enhancements

### Potential Improvements

1. **Minimum Size Enforcement**: Prevent window from becoming too small
2. **Aspect Ratio Handling**: Special handling for very wide/tall screens
3. **Mobile Optimization**: Touch controls for mobile devices
4. **Performance Scaling**: Adjust game speed based on screen size
5. **Accessibility**: Font size scaling based on screen size

### Configuration Options

- **Safe Zones**: Configurable margins for UI elements
- **Scaling Factors**: User-adjustable UI scaling multipliers
- **Aspect Ratio Lock**: Option to maintain specific aspect ratios

## Technical Notes

### Godot-Specific Features Used

- **Viewport System**: For screen size detection
- **CanvasLayer**: For UI scaling
- **Anchor System**: For relative positioning
- **Signal System**: For resize event handling

### Best Practices Applied

- **Percentage-Based Positioning**: All positions use screen size percentages
- **Single Source of Truth**: One function handles all positioning
- **Event-Driven Updates**: Automatic updates on window changes
- **Separation of Concerns**: UI scaling separate from game logic

This system ensures the game provides a consistent experience regardless of screen size or window configuration.
