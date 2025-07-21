extends CharacterBody2D


const GRAVITY = 8000
const SPEED = 1000.0
const JUMP_VELOCITY = -2250.0

# Bounce immunity system
var bounce_immunity_time: float = 0.0
const BOUNCE_IMMUNITY_DURATION: float = 0.3  # 0.3 seconds of immunity

# Plant interaction system
@export var plant_interaction_range: float = 1000.0  # How close player needs to be to control plants
var debug_plant_interaction: bool = true

# Drop-through platform system
var drop_through_timer: float = 0.0
const DROP_THROUGH_DURATION: float = 0.2  # How long to ignore one-way platforms


func _physics_process(delta: float) -> void:
	# Update bounce immunity timer
	if bounce_immunity_time > 0:
		bounce_immunity_time -= delta
	
	# Update drop-through timer
	if drop_through_timer > 0:
		drop_through_timer -= delta
	
	# Handle drop-through input (check for down arrow key)
	if Input.is_action_just_pressed("move_down"):
		if is_on_floor():
			# Simple drop-through: disable collision temporarily and move down
			drop_through_timer = DROP_THROUGH_DURATION
			position.y += 1  # Move down to start falling through platforms
			print("Dropping through platform!")
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# Only apply horizontal input if not in bounce immunity
	if bounce_immunity_time <= 0:
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	else:
		# During bounce immunity, only apply friction, don't allow input control
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.1)  # Much slower deceleration during bounce

	# Move and handle collisions using Godot's recommended approach  
	# Temporarily disable one-way platform collision during drop-through
	if drop_through_timer > 0:
		# Save current collision state
		var original_collision_layer = collision_layer
		var original_collision_mask = collision_mask
		
		# Disable collision with platforms (assuming layer 1)
		set_collision_mask_value(1, false)
		move_and_slide()
		
		# Restore collision state  
		collision_layer = original_collision_layer
		collision_mask = original_collision_mask
	else:
		move_and_slide()
	
	# Check for collisions with mushroom objects
	_check_mushroom_collisions()

func _unhandled_input(event: InputEvent) -> void:
	# Intercept plant control inputs and route them to the nearest plant
	var action_name = ""
	
	if event.is_action_pressed("grow"):
		action_name = "grow"
	elif event.is_action_pressed("flor"):
		action_name = "flor"
	elif event.is_action_pressed("grow_u"):
		action_name = "grow_u"
	elif event.is_action_pressed("flor_u"):
		action_name = "flor_u"
	elif event.is_action_pressed("clear_runes"):
		action_name = "clear_runes"
	
	if action_name != "":
		var nearest_plant = _find_nearest_plant()
		if nearest_plant:
			# Call the plant's input handling method directly
			if nearest_plant.has_method("handle_plant_input"):
				nearest_plant.handle_plant_input(action_name)
				get_viewport().set_input_as_handled()  # Prevent other nodes from receiving this input
				
				if debug_plant_interaction:
					print("Controlled ", nearest_plant.name, " (", action_name, ")")
			else:
				print("ERROR: Nearest plant does not have handle_plant_input method")
		else:
			if debug_plant_interaction:
				print("No plants within range (", plant_interaction_range, " pixels)")

func _find_nearest_plant() -> Node:
	var nearest_plant: Node = null
	var nearest_distance: float = plant_interaction_range
	
	# Get all nodes in the scene tree
	var all_nodes = get_tree().get_nodes_in_group("plants")
	
	# If no plants in group, search manually
	if all_nodes.is_empty():
		all_nodes = _find_all_plants_in_scene()
	
	# Find the closest plant within range
	for plant in all_nodes:
		if plant and plant != self:  # Don't include the player
			var distance = global_position.distance_to(plant.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_plant = plant
	
	return nearest_plant

func _find_all_plants_in_scene() -> Array:
	var plants = []
	var root = get_tree().current_scene
	
	# Recursively search for plants
	_search_for_plants(root, plants)
	
	return plants

func _search_for_plants(node: Node, plants: Array) -> void:
	# Check if this node is a plant (has plant control methods)
	if _is_plant(node):
		plants.append(node)
	
	# Recursively search children
	for child in node.get_children():
		_search_for_plants(child, plants)

func _is_plant(node: Node) -> bool:
	# Check if the node has the new plant input handling method
	return node.has_method("handle_plant_input")

func _check_mushroom_collisions() -> void:
	# Check all collisions that occurred during move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if we collided with a TileMapLayer (which would be the mushroom tiles)
		if collider and collider is TileMapLayer:
			_check_if_mushroom_tilemap(collision, collider)
		
		# Check if we collided with a mushroom StaticBody2D directly
		elif collider and collider is StaticBody2D:
			if collider.has_method("get_state_m_string"):
				_handle_mushroom_collision(collision, collider)

func _check_if_mushroom_tilemap(collision: KinematicCollision2D, tilemap: TileMapLayer) -> void:
	# Check if this TileMapLayer belongs to a mushroom
	var parent = tilemap.get_parent()
	
	if parent and parent is StaticBody2D:
		if parent.has_method("get_state_m_string"):
			_handle_mushroom_collision(collision, parent)
		elif parent.has_method("is_bramble"):
			# print("Player touched bramble!")
			_handle_bramble_collision(parent)

func _handle_mushroom_collision(collision: KinematicCollision2D, mushroom: StaticBody2D) -> void:
	# Don't apply bounce if we're already in bounce immunity (prevents multiple bounces)
	if bounce_immunity_time > 0:
		return
	
	# Get mushroom state and collision info
	var mushroom_state = mushroom.get_state_m_string()
	var collision_normal = collision.get_normal()
	var collision_point = collision.get_position()
	
	# Get bounce vector from mushroom based on its state and collision direction
	var bounce_vector = mushroom.get_bounce_vector(collision_normal)
	
	# Apply the bounce if we got a valid bounce vector
	if bounce_vector != Vector2.ZERO:
		velocity = bounce_vector
		bounce_immunity_time = BOUNCE_IMMUNITY_DURATION  # Start bounce immunity
		print("BOUNCE! From ", mushroom_state, " mushroom")
		# print("  Applied velocity: ", velocity)
		# print("  Collision normal: ", collision_normal)
		# print("  Bounce immunity active for ", BOUNCE_IMMUNITY_DURATION, " seconds")
	# else:
		# Debug output for when no bounce occurs
		# print("No bounce from mushroom collision")
		# print("  Mushroom state: '", mushroom_state, "'")
		# print("  Collision normal: ", collision_normal)

func _handle_bramble_collision(bramble: StaticBody2D) -> void:
	# Call the bramble's contact method to reset the level
	bramble.on_player_contact()

# Helper function to set plant interaction range
func set_plant_interaction_range(new_range: float) -> void:
	plant_interaction_range = new_range
	# if debug_plant_interaction:
		# print("Plant interaction range set to: ", plant_interaction_range)

# Helper function to toggle debug mode
func set_debug_plant_interaction(enabled: bool) -> void:
	debug_plant_interaction = enabled
	# print("Plant interaction debugging ", "enabled" if enabled else "disabled")
