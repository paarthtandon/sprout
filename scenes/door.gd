extends StaticBody2D

# Color variants enum (matching button colors)
enum DoorColor {
	RED,
	GREEN,
	BLUE
}

# Exported properties
@export var color_variant: DoorColor = DoorColor.RED
@export var door_height: float = 128.0  # How much the door moves when opening
@export var animation_duration: float = 0.5
@export var debug_mode: bool = true

# Door state
var is_open: bool = false
var is_animating: bool = false
var closed_position: Vector2
var open_position: Vector2
var tile_map: TileMapLayer
var tween: Tween

# Tile coordinate mappings for each color variant (door appearance only)
var color_tile_coords = {
	DoorColor.RED: Vector2i(18, 0),
	DoorColor.GREEN: Vector2i(21, 0),
	DoorColor.BLUE: Vector2i(24, 0)
}

func _ready() -> void:
	# Store the initial (closed) position
	closed_position = global_position
	open_position = closed_position + Vector2(0, -door_height)  # Slide up by door height
	
	# Get the TileMapLayer for visual updates
	tile_map = $TileMapLayer
	if not tile_map:
		push_error("TileMapLayer node not found! Please check door scene structure.")
	
	# Set initial visual state (color only, no open/close tiles)
	_update_visual_state()
	
	# if debug_mode:
		# print("Door initialized at position: ", global_position)
		# print("Color variant: ", DoorColor.keys()[color_variant])
		# print("Closed position: ", closed_position)
		# print("Open position: ", open_position)
		# print("Door tile: ", _get_door_coords())

func _get_door_coords() -> Vector2i:
	return color_tile_coords[color_variant]

func set_door_state(should_open: bool) -> void:
	if should_open == is_open:
		return  # Already in desired state
	
	is_open = should_open
	_animate_door()
	
	# if debug_mode:
		# print("Door ", "OPENING" if should_open else "CLOSING")

func _animate_door() -> void:
	is_animating = true
	
	# Stop any existing tween (allows reversing mid-animation)
	if tween:
		tween.kill()
	
	# Create new tween for smooth animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animate to the target position
	var target_position = open_position if is_open else closed_position
	tween.tween_property(self, "global_position", target_position, animation_duration)
	
	# Wait for animation to complete
	await tween.finished
	
	is_animating = false
	
	# if debug_mode:
		# print("Door animation completed - State: ", "OPEN" if is_open else "CLOSED")

func _update_visual_state() -> void:
	if not tile_map:
		return
	
	# Set the door tile based on color (same tile for open and closed)
	var tile_coords = _get_door_coords()
	
	# Update the tile at position (0,0) in the tilemap
	tile_map.set_cell(Vector2i(0, 0), 2, tile_coords)  # Source ID 2, door tile
	
	# if debug_mode:
		# print("Door visual updated to tile: ", tile_coords)

# Helper function to change color variant
func set_color_variant(new_color: DoorColor) -> void:
	color_variant = new_color
	_update_visual_state()  # Apply the change immediately
	
	# if debug_mode:
		# print("Door color changed to: ", DoorColor.keys()[color_variant])

# Helper function to check if door is open
func is_door_open() -> bool:
	return is_open

# Helper function to toggle door state
func toggle_door() -> void:
	set_door_state(not is_open) 
