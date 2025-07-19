extends Camera2D
class_name CameraController

# Camera settings
@export var snap_to_rooms: bool = true  # If false, uses smooth transitions
@export var smooth_speed: float = 5.0  # Speed for smooth transitions
@export var room_transition_threshold: float = 100.0  # Distance before starting transition
@export var debug_mode: bool = true

# Current state
var current_room: Room = null
var target_position: Vector2
var is_transitioning: bool = false
var rooms: Array[Room] = []

# Player reference
var player: Node2D

signal room_changed(new_room: Room, old_room: Room)

func _ready() -> void:
	# Find player
	player = get_tree().current_scene.find_child("Player", true, false)
	if not player:
		push_error("CameraController: Could not find Player node!")
		return
	
	# Find all rooms in the scene
	_discover_rooms()
	
	# Set initial position
	if rooms.size() > 0:
		var starting_room = _find_room_containing_player()
		if starting_room:
			_set_current_room(starting_room, true)  # Snap to first room
	
	if debug_mode:
		print("CameraController initialized with ", rooms.size(), " rooms")

func _discover_rooms() -> void:
	rooms.clear()
	var scene_root = get_tree().current_scene
	_find_rooms_recursive(scene_root)
	
	# Connect to room signals
	for room in rooms:
		if not room.room_entered.is_connected(_on_room_entered):
			room.room_entered.connect(_on_room_entered)
		if not room.room_exited.is_connected(_on_room_exited):
			room.room_exited.connect(_on_room_exited)
	
	if debug_mode:
		var room_names = []
		for room in rooms:
			room_names.append(room.room_name)
		print("Discovered rooms: ", room_names)

func _find_rooms_recursive(node: Node) -> void:
	if node is Room:
		rooms.append(node as Room)
	
	for child in node.get_children():
		_find_rooms_recursive(child)

func _find_room_containing_player() -> Room:
	if not player:
		return null
		
	for room in rooms:
		var room_bounds = room.get_camera_bounds()
		if room_bounds.has_point(player.global_position):
			return room
	return null

func _process(delta: float) -> void:
	if not player:
		return
	
	# Handle smooth camera transitions
	if is_transitioning and not snap_to_rooms:
		global_position = global_position.move_toward(target_position, smooth_speed * delta * 100)
		
		# Check if we've reached the target
		if global_position.distance_to(target_position) < 5.0:
			global_position = target_position
			is_transitioning = false
			if debug_mode:
				print("Camera transition completed to: ", target_position)

func _on_room_entered(room: Room) -> void:
	if room != current_room:
		_set_current_room(room, snap_to_rooms)

func _on_room_exited(room: Room) -> void:
	# Only handle if we're leaving the current room
	if room == current_room:
		# Find which room the player is now in
		var new_room = _find_room_containing_player()
		if new_room and new_room != current_room:
			_set_current_room(new_room, snap_to_rooms)

func _set_current_room(room: Room, snap: bool = false) -> void:
	var old_room = current_room
	current_room = room
	target_position = room.camera_position
	
	# Update room active states
	for r in rooms:
		r.set_active(r == room)
	
	if snap:
		global_position = target_position
		is_transitioning = false
		if debug_mode:
			print("Camera snapped to room: ", room.room_name, " at ", target_position)
	else:
		is_transitioning = true
		if debug_mode:
			print("Camera transitioning to room: ", room.room_name, " at ", target_position)
	
	# Emit signal
	room_changed.emit(room, old_room)

# Public methods for manual room switching
func switch_to_room(room_name: String, snap: bool = false) -> bool:
	for room in rooms:
		if room.room_name == room_name:
			_set_current_room(room, snap)
			return true
	
	if debug_mode:
		print("Room not found: ", room_name)
	return false

func switch_to_room_by_index(index: int, snap: bool = false) -> bool:
	if index >= 0 and index < rooms.size():
		_set_current_room(rooms[index], snap)
		return true
	
	if debug_mode:
		print("Room index out of range: ", index)
	return false

# Get current room info
func get_current_room() -> Room:
	return current_room

func get_room_count() -> int:
	return rooms.size()

func get_room_names() -> Array[String]:
	var names: Array[String] = []
	for room in rooms:
		names.append(room.room_name)
	return names 
