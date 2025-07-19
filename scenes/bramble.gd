extends StaticBody2D

var debug_mode := true

func _ready() -> void:
	pass
	# if debug_mode:
		# print("Bramble initialized at position: ", global_position)

# Helper function to identify this as a bramble for collision detection
func is_bramble() -> bool:
	return true

# Function called when player touches the bramble
func on_player_contact() -> void:
	if debug_mode:
		print("Player touched bramble! Resetting level...")
	
	# Use deferred call to safely reset the scene
	call_deferred("_reset_scene")

func _reset_scene() -> void:
	# Check if tree is still valid
	var tree = get_tree()
	if tree == null:
		print("ERROR: Tree is null, cannot reset scene")
		return
	
	# if debug_mode:
		# print("Reloading scene...")
	
	tree.reload_current_scene() 
