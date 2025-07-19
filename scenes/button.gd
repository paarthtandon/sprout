extends Area2D

# Color variants enum
enum ButtonColor {
	RED,
	GREEN, 
	BLUE
}

# Exported properties for easy configuration
@export var color_variant: ButtonColor = ButtonColor.RED
@export var associated_door_path: NodePath  # Path to the door this button controls
@export var debug_mode: bool = true

# Button state
var is_pressed: bool = false
var objects_on_button: Array = []  # Track what's currently on the button
var associated_door: Node = null
var tile_map: TileMapLayer

# Tile coordinate mappings for each color variant
var color_tile_coords = {
	ButtonColor.RED: {
		"unpressed": Vector2i(17, 0),
		"pressed": Vector2i(16, 0)
	},
	ButtonColor.GREEN: {
		"unpressed": Vector2i(20, 0),
		"pressed": Vector2i(19, 0)
	},
	ButtonColor.BLUE: {
		"unpressed": Vector2i(23, 0),
		"pressed": Vector2i(22, 0)
	}
}

func _ready() -> void:
	# Connect area signals for detection
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Get the TileMapLayer for visual updates
	tile_map = $TileMapLayer
	if not tile_map:
		push_error("TileMapLayer node not found! Please check scene structure.")
	
	# Find the associated door
	if associated_door_path:
		associated_door = get_node(associated_door_path)
		if not associated_door:
			push_error("Could not find associated door at path: " + str(associated_door_path))
		
		# Set the door's color to match this button
		if associated_door and associated_door.has_method("set_color_variant"):
			associated_door.set_color_variant(color_variant)
	
	# Set initial visual state
	_update_visual_state()
	
	# if debug_mode:
		# print("Button initialized at position: ", global_position)
		# print("Color variant: ", ButtonColor.keys()[color_variant])
		# print("Associated door: ", associated_door.name if associated_door else "None")
		# print("Unpressed tile: ", _get_unpressed_coords())
		# print("Pressed tile: ", _get_pressed_coords())

func _get_unpressed_coords() -> Vector2i:
	return color_tile_coords[color_variant]["unpressed"]

func _get_pressed_coords() -> Vector2i:
	return color_tile_coords[color_variant]["pressed"]

func _on_body_entered(body: Node2D) -> void:
	# Check if it's the player or betel
	if _is_valid_activator(body):
		objects_on_button.append(body)
		_update_button_state()
		
		# if debug_mode:
			# print(body.name, " stepped on button")

func _on_body_exited(body: Node2D) -> void:
	# Remove from the list if it was tracked
	if body in objects_on_button:
		objects_on_button.erase(body)
		_update_button_state()
		
		# if debug_mode:
			# print(body.name, " stepped off button")

func _is_valid_activator(body: Node2D) -> bool:
	# Check if the body is a player or betel
	if body.name == "Player":
		return true
	elif body.name == "Betel":
		return true
	elif body.has_method("is_betel"):  # Alternative check for betel
		return true
	return false

func _update_button_state() -> void:
	var should_be_pressed = objects_on_button.size() > 0
	
	# Only trigger door action if state actually changed
	if should_be_pressed != is_pressed:
		is_pressed = should_be_pressed
		_trigger_door()
		_update_visual_state()  # Update the button sprite
		
		# if debug_mode:
			# print("Button ", "PRESSED" if is_pressed else "RELEASED")

func _update_visual_state() -> void:
	if not tile_map:
		return
	
	# Choose the correct tile based on button state and color
	var tile_coords = _get_pressed_coords() if is_pressed else _get_unpressed_coords()
	
	# Update the tile at position (0,0) in the tilemap
	tile_map.set_cell(Vector2i(0, 0), 2, tile_coords)  # Source ID 2, new tile coords
	
	# if debug_mode:
		# print("Button visual updated to tile: ", tile_coords)

func _trigger_door() -> void:
	if not associated_door:
		# if debug_mode:
			# print("No associated door to trigger")
		return
	
	# Tell the door to open or close
	if associated_door.has_method("set_door_state"):
		associated_door.set_door_state(is_pressed)
	else:
		push_error("Associated door does not have set_door_state method")

# Helper function to manually set the associated door (useful for dynamic setup)
func set_associated_door(door_node: Node) -> void:
	associated_door = door_node
	# if debug_mode:
		# print("Button associated with door: ", door_node.name)

# Helper function to change color variant
func set_color_variant(new_color: ButtonColor) -> void:
	color_variant = new_color
	_update_visual_state()  # Apply the change immediately
	
	# Update associated door color too
	if associated_door and associated_door.has_method("set_color_variant"):
		associated_door.set_color_variant(color_variant)
	
	# if debug_mode:
		# print("Button color changed to: ", ButtonColor.keys()[color_variant]) 
