extends CharacterBody2D

# Exported properties for easy configuration
@export var walk_direction: Vector2 = Vector2(1, 0)  # Direction to walk (1,0 = right, -1,0 = left, etc.)
@export var walk_speed: float = 200.0
@export var debug_mode: bool = true

# Movement properties
const GRAVITY = 8000
var starting_position: Vector2
var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	# Store the starting position for respawning
	starting_position = global_position
	
	# Get the AnimatedSprite2D node
	animated_sprite = $AnimatedSprite2D
	if not animated_sprite:
		push_error("AnimatedSprite2D node not found! Please check scene structure.")
	
	# Normalize the walk direction and start walking animation
	walk_direction = walk_direction.normalized()
	_start_walking_animation()
	
	# if debug_mode:
		# print("Betel initialized at position: ", starting_position)
		# print("Walking direction: ", walk_direction)
		# print("Walking speed: ", walk_speed)

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Set horizontal movement based on walk direction
	velocity.x = walk_direction.x * walk_speed
	
	# Move the betel
	move_and_slide()
	
	# Check for bramble and mushroom collisions
	_check_collisions()

func _check_collisions() -> void:
	# Check all collisions that occurred during move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if we collided with a TileMapLayer (bramble/mushroom tiles)
		if collider and collider is TileMapLayer:
			_check_if_bramble_or_mushroom_tilemap(collision, collider)
		
		# Check if we collided with a bramble or mushroom StaticBody2D directly
		elif collider and collider is StaticBody2D:
			if collider.has_method("is_bramble"):
				_handle_bramble_collision(collider)
			elif collider.has_method("get_state_m_string"):
				_handle_mushroom_collision(collider)

func _check_if_bramble_or_mushroom_tilemap(collision: KinematicCollision2D, tilemap: TileMapLayer) -> void:
	# Check if this TileMapLayer belongs to a bramble or mushroom
	var parent = tilemap.get_parent()
	
	if parent and parent is StaticBody2D:
		if parent.has_method("is_bramble"):
			_handle_bramble_collision(parent)
		elif parent.has_method("get_state_m_string"):
			_handle_mushroom_collision(parent)

func _handle_bramble_collision(bramble: StaticBody2D) -> void:
	if debug_mode:
		print("Betel touched bramble! Respawning...")
	
	# Respawn at starting position
	respawn()

func _handle_mushroom_collision(mushroom: StaticBody2D) -> void:
	# Get the mushroom's current state
	var mushroom_state = mushroom.get_state_m_string()
	
	# Check if the mushroom has "F" (flower) in its state
	if "F" in mushroom_state:
		# if debug_mode:
			# print("Betel hit mushroom with flower state '", mushroom_state, "' - reversing direction!")
		
		# Reverse the walk direction
		walk_direction.x = -walk_direction.x
		walk_direction.y = -walk_direction.y  # In case of diagonal movement
		
		# Update animation to match new direction
		_start_walking_animation()
	# else:
		# if debug_mode:
			# print("Betel hit mushroom with state '", mushroom_state, "' - no flower, no direction change")

func respawn() -> void:
	# Reset position to starting location
	global_position = starting_position
	
	# Reset velocity
	velocity = Vector2.ZERO
	
	# Restart walking animation
	_start_walking_animation()
	
	if debug_mode:
		print("Betel respawned at: ", starting_position)

func _start_walking_animation() -> void:
	if not animated_sprite:
		return
	
	# Set the walking animation based on direction
	if walk_direction.x > 0:
		animated_sprite.flip_h = false  # Walking right
	elif walk_direction.x < 0:
		animated_sprite.flip_h = true   # Walking left
	
	# Play walking animation (assumes "walk" animation exists)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
	elif animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")
	# else:
		# if debug_mode:
			# print("No walking animation found, using default")

# Helper function to change direction (useful for future features)
func set_walk_direction(new_direction: Vector2) -> void:
	walk_direction = new_direction.normalized()
	_start_walking_animation()
	
	# if debug_mode:
		# print("Betel direction changed to: ", walk_direction)

# Helper function to change speed
func set_walk_speed(new_speed: float) -> void:
	walk_speed = new_speed
	
	# if debug_mode:
		# print("Betel speed changed to: ", walk_speed)

# Helper function for button detection
func is_betel() -> bool:
	return true 
