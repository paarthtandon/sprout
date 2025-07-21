extends Area2D
class_name Room

# Room properties
@export var room_name: String = "Room"
@export var camera_position: Vector2 = Vector2.ZERO
@export var room_size: Vector2 = Vector2(1536, 1280)  # Default room size
@export var transition_speed: float = 2.0  # How fast camera moves to this room
@export var debug_mode: bool = true

# Visual debugging
var debug_color: Color = Color.CYAN
var is_active: bool = false

signal room_entered(room: Room)
signal room_exited(room: Room)

func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision shape if not already present
	_setup_collision_shape()
	
	if debug_mode:
		print("Room '", room_name, "' initialized at position: ", global_position)
		print("  Camera position: ", camera_position)
		print("  Room size: ", room_size)

func _setup_collision_shape() -> void:
	# Create collision shape if one doesn't exist
	var collision_shape = get_node_or_null("CollisionShape2D")
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
		
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = room_size
		collision_shape.shape = rect_shape
		
		if debug_mode:
			print("Created collision shape for room '", room_name, "'")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_active = true
		room_entered.emit(self)
		
		if debug_mode:
			print("Player entered room: ", room_name)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_active = false
		room_exited.emit(self)
		
		if debug_mode:
			print("Player exited room: ", room_name)

# Get the camera bounds for this room
func get_camera_bounds() -> Rect2:
	var half_size = room_size / 2
	return Rect2(camera_position - half_size, room_size)

# Draw debug visualization in editor
func _draw() -> void:
	if Engine.is_editor_hint():
		var rect = Rect2(-room_size / 2, room_size)
		draw_rect(rect, debug_color, false, 4.0)
		
		# Draw camera center point
		draw_circle(camera_position - global_position, 20, Color.RED)
	elif debug_mode:
		# Only show room bounds in game, not camera center
		var rect = Rect2(-room_size / 2, room_size)
		draw_rect(rect, debug_color, false, 4.0)

# Set the room as active (called by camera controller)
func set_active(active: bool) -> void:
	is_active = active
	if debug_mode:
		print("Room '", room_name, "' set to ", "active" if active else "inactive") 
