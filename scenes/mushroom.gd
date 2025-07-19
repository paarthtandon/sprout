extends StaticBody2D

# Exported variable to control maximum number of runes (state items)
@export var max_runes: int = 2

const BASE_LOC = Vector2i(0, 0) # base location in scene
const SOURCE_ID = 2  # Correct source ID from tileset.tres

# Tile atlas coordinates
const BABY = Vector2i(16, 1)
const GROWN = Vector2i(17, 1)
const WIDE = Vector2i(18, 1)
const GROW_WIDE = Vector2i(19, 1)

const STATES = {
	"": [{"tile": BABY, "pos": Vector2i(0, 0)}],
	"G": [{"tile": GROWN, "pos": Vector2i(0, 0)}],
	"F": [{"tile": WIDE, "pos": Vector2i(0, 0)}],
	"GF": [{"tile": GROW_WIDE, "pos": Vector2i(0, 0)}],
	"FG": [{"tile": GROW_WIDE, "pos": Vector2i(0, 0)}],
}

var tile_map: TileMapLayer
var state_m := []   # e.g. [ "F", "G" ]
var debug_mode := true
var rune_ui: Node2D  # Reference to the rune UI component

# Bounce properties - exported for easy tuning
@export var growth_bounce_force: float = 3500.0
@export var flower_bounce_force: float = 3500.0
@export var flower_bounce_angle: float = 45.0  # Angle in degrees (0 = horizontal, 90 = vertical)

# Collision shapes for different bounce types
var growth_collision: CollisionShape2D
var flower_left_collision: CollisionShape2D
var flower_right_collision: CollisionShape2D

func _ready() -> void:
	tile_map = $TileMapLayer
	if not tile_map:
		push_error("TileMapLayer node not found! Please check scene structure.")
		return
	
	# Find the rune UI component
	rune_ui = $RuneUI
	if not rune_ui:
		print("RuneUI not found - rune display will not be available")
	
	# Create collision shapes for bouncing
	_setup_collision_shapes()
	
	# Add this mushroom to the plants group for proximity detection
	add_to_group("plants")
		
	# print("Mushroom system initialized at position: ", global_position)
	# print("Available input actions: grow (Z), flor (X), grow_u (A), flor_u (S)")
	# print("NOTE: Player must be within range to control this plant")
	build_state_m()

func _setup_collision_shapes() -> void:
	# Create collision shape for growth (vertical bouncing) - top of mushroom
	growth_collision = CollisionShape2D.new()
	var growth_shape = RectangleShape2D.new()
	growth_shape.size = Vector2(100, 20)  # Wide, thin rectangle on top
	growth_collision.shape = growth_shape
	growth_collision.position = Vector2(0, -40)  # Positioned at top of tile
	add_child(growth_collision)
	
	# Create collision shape for flower left side (45-degree bouncing)
	flower_left_collision = CollisionShape2D.new()
	var flower_left_shape = RectangleShape2D.new()
	flower_left_shape.size = Vector2(20, 80)  # Tall, thin rectangle on left
	flower_left_collision.shape = flower_left_shape
	flower_left_collision.position = Vector2(-50, 0)  # Positioned at left side
	add_child(flower_left_collision)
	
	# Create collision shape for flower right side (45-degree bouncing)
	flower_right_collision = CollisionShape2D.new()
	var flower_right_shape = RectangleShape2D.new()
	flower_right_shape.size = Vector2(20, 80)  # Tall, thin rectangle on right
	flower_right_collision.shape = flower_right_shape
	flower_right_collision.position = Vector2(50, 0)  # Positioned at right side
	add_child(flower_right_collision)
	
	# if debug_mode:
		# print("Collision shapes created for mushroom bouncing")

# Handle input for plant control actions - called directly by player proximity system
func handle_plant_input(action: String) -> void:
	match action:
		"grow":
			grow()
		"flor":
			flor()
		"grow_u":
			grow_u()
		"flor_u":
			flor_u()
		"clear_runes":
			clear_runes()
		_:
			if debug_mode:
				print("Unknown plant action: ", action)

func grow() -> void:
	if state_m.count("G") < 1 and len(state_m) < max_runes:
		state_m.push_front("G")
		# if debug_mode:
			# print("Growing! New state_m: ", state_m)
	# else:
		# if debug_mode:
			# print("Cannot grow: Max size reached or too many growth segments")
	build_state_m()

func flor() -> void:
	if state_m.count("F") < 1 and len(state_m) < max_runes:
		state_m.push_front("F")
		# if debug_mode:
			# print("Flowering! New state_m: ", state_m)
	# else:
		# if debug_mode:
			# print("Cannot flower: Already has flower or too many segments")
	build_state_m()

func grow_u() -> void:
	var had_growth = state_m.has("G")
	state_m.erase("G")
	# if debug_mode:
		# if had_growth:
			# print("Growth removed! New state_m: ", state_m)
		# else:
			# print("No growth to remove")
	build_state_m()

func flor_u() -> void:
	var had_flower = state_m.has("F")
	state_m.erase("F")
	# if debug_mode:
		# if had_flower:
			# print("Flower removed! New state_m: ", state_m)
		# else:
			# print("No flower to remove")
	build_state_m()

func build_state_m() -> void:
	if not tile_map:
		push_error("TileMapLayer is null, cannot build state_m")
		return
		
	# 1) Make a key string like "GF" or ""
	var state_m_copy = state_m.duplicate()
	state_m_copy.reverse()
	var key = ""
	for s in state_m_copy:
		key += s

	# if debug_mode:
		# print("Building state_m: '", key, "' from state_m array: ", state_m)

	# 2) Clear the tilemap
	tile_map.clear()

	# 3) Check if state_m exists
	if not STATES.has(key):
		push_error("Invalid state_m key: '" + key + "'. Available state_ms: " + str(STATES.keys()))
		return

	# 4) Stamp out each tile for this state_m
	var tile_count = 0
	for entry in STATES.get(key, []):
		var cell = BASE_LOC + entry.pos
		var atlas = entry.tile
		
		tile_map.set_cell(cell, SOURCE_ID, atlas)
		tile_count += 1
		
		# if debug_mode:
			# print("  Placed tile at ", cell, " with atlas coords ", atlas)
	
	# 5) Update collision shapes based on current state
	_update_collision_shapes()
	
	# 6) Fix player position if they're stuck after collision change
	_fix_player_position_if_stuck()
	
	# if debug_mode:
		# print("State build complete. Placed ", tile_count, " tiles.")
	
	# Notify UI of state change
	_notify_ui_update()

func _update_collision_shapes() -> void:
	# Disable all collision shapes first
	if growth_collision:
		growth_collision.disabled = true
	if flower_left_collision:
		flower_left_collision.disabled = true
	if flower_right_collision:
		flower_right_collision.disabled = true
	
	# Enable collision shapes based on current state
	var has_growth = _has_growth()
	var has_flower = _has_flower()
	
	if has_growth and growth_collision:
		growth_collision.disabled = false
		# if debug_mode:
			# print("  Enabled growth collision (vertical bouncing)")
	
	if has_flower and flower_left_collision and flower_right_collision:
		flower_left_collision.disabled = false
		flower_right_collision.disabled = false
		# if debug_mode:
			# print("  Enabled flower collisions (side bouncing)")

# Helper function to get current state_m as string
func get_state_m_string() -> String:
	var state_m_copy = state_m.duplicate()
	state_m_copy.reverse()
	var key = ""
	for s in state_m_copy:
		key += s
	return key

# Helper function to reset mushroom to initial state_m
func reset() -> void:
	state_m.clear()
	# if debug_mode:
		# print("Mushroom reset to initial state_m")
	build_state_m()

# Clear all runes (same as reset)
func clear_runes() -> void:
	state_m.clear()
	if debug_mode:
		print("All runes cleared from mushroom!")
	build_state_m()

# Notify UI of state changes
func _notify_ui_update() -> void:
	if rune_ui and rune_ui.has_method("update_display"):
		rune_ui.update_display()

# Helper function to check if mushroom has flower
func _has_flower() -> bool:
	return state_m.has("F")

# Helper function to check if mushroom has growth
func _has_growth() -> bool:
	return state_m.has("G")

# Helper function to set debug mode
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	# print("Debug mode ", "enabled" if enabled else "disabled")

# Fix player position if they get stuck inside collision after state change
func _fix_player_position_if_stuck() -> void:
	# Find the player in the scene
	var player = get_tree().current_scene.find_child("Player", true, false)
	if not player:
		return
	
	# Check if player is close enough to potentially be stuck
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > 200:  # Only check if player is nearby
		return
	
	# Check if player is overlapping with our collision shapes
	var space_state = get_world_2d().direct_space_state
	var player_shape = player.get_node("CollisionShape2D").shape
	var player_transform = Transform2D(0, player.global_position)
	
	# Create a collision query for the player's current position
	var query = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 1  # Check against collision layer 1
	query.shape = player_shape
	query.transform = player_transform
	
	var collisions = space_state.intersect_shape(query)
	
	# Check if any collision is with this mushroom
	for collision in collisions:
		var collider = collision.get("collider")
		if collider == self:
			# Player is stuck! Push them to safety
			_push_player_to_safety(player)
			break

func _push_player_to_safety(player: CharacterBody2D) -> void:
	# Try pushing the player in different directions to find a safe spot
	var push_directions = [
		Vector2(0, -150),   # Up (preferred for mushrooms)
		Vector2(-100, -100), # Up-left diagonal
		Vector2(100, -100),  # Up-right diagonal
		Vector2(-150, 0),    # Left
		Vector2(150, 0),     # Right
		Vector2(0, 50)       # Down (last resort)
	]
	
	var original_position = player.global_position
	
	for direction in push_directions:
		var test_position = original_position + direction
		
		# Test if this position is safe
		if _is_position_safe_for_player(player, test_position):
			player.global_position = test_position
			if debug_mode:
				print("Player pushed to safety: ", direction)
			return
	
	# If no safe position found, push up as fallback
	player.global_position = original_position + Vector2(0, -200)
	if debug_mode:
		print("Player pushed up (fallback)")

func _is_position_safe_for_player(player: CharacterBody2D, test_position: Vector2) -> bool:
	# Check if the test position is free of collisions
	var space_state = get_world_2d().direct_space_state
	var player_shape = player.get_node("CollisionShape2D").shape
	var test_transform = Transform2D(0, test_position)
	
	var query = PhysicsShapeQueryParameters2D.new()
	query.collision_mask = 1  # Check against solid objects
	query.shape = player_shape
	query.transform = test_transform
	query.exclude = [player]  # Don't check against the player itself
	
	var collisions = space_state.intersect_shape(query)
	return collisions.is_empty()  # Safe if no collisions

# Function to handle bouncing - called by player when collision is detected
func get_bounce_vector(collision_normal: Vector2) -> Vector2:
	var has_growth = _has_growth()
	var has_flower = _has_flower()
	
	# if debug_mode:
		# print("Getting bounce vector for collision normal: ", collision_normal)
		# print("  Has growth: ", has_growth, ", Has flower: ", has_flower)
	
	# Determine bounce direction based on collision normal and mushroom state
	# Note: collision_normal points FROM the surface TO the colliding object
	if has_growth and collision_normal.y < -0.5:  # Hitting mushroom from below (normal points down)
		# if debug_mode:
			# print("  -> Vertical bounce (growth)")
		return Vector2(0, -growth_bounce_force)  # Straight up
	
	elif has_flower:
		var bounce_force = flower_bounce_force
		var bounce_angle = deg_to_rad(flower_bounce_angle)
		
		var bounce_x = cos(bounce_angle) * bounce_force
		var bounce_y = -sin(bounce_angle) * bounce_force  # Negative for upward
		
		if collision_normal.x < -0.5:  # Hitting from right side (normal points left)
			# if debug_mode:
				# print("  -> Diagonal bounce (flower, hit from right) at ", flower_bounce_angle, " degrees")
			return Vector2(-bounce_x, bounce_y)  # Bounce left and up
		elif collision_normal.x > 0.5:  # Hitting from left side (normal points right)
			# if debug_mode:
				# print("  -> Diagonal bounce (flower, hit from left) at ", flower_bounce_angle, " degrees")
			return Vector2(bounce_x, bounce_y)  # Bounce right and up
	
	# No bounce if no matching state/direction
	# if debug_mode:
		# print("  -> No bounce")
	return Vector2.ZERO
