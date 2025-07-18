extends Area2D

const BASE_LOC = Vector2i(2, 7) # base location in scene
const SOURCE_ID = 2  # Correct source ID from tileset.tres

# Tile atlas coordinates
const BABY = Vector2i(16, 2)
const STALK = Vector2i(17, 2)
const HEAD = Vector2i(18, 2)
const LEFT_TIP = Vector2i(19, 2)
const LEFT_MID = Vector2i(20, 2)
const FLOR = Vector2i(21, 2)
const RIGHT_MID = Vector2i(22, 2)
const RIGHT_TIP = Vector2i(23, 2)

const STATES = {
	"": [{"tile": BABY, "pos": Vector2i(0, 0)}],
	
	"G": [{"tile": STALK, "pos": Vector2i(0, 0)},
			{"tile": STALK, "pos": Vector2i(0, 1)},
			{"tile": HEAD, "pos": Vector2i(0, 2)}],
			
	"GG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 {"tile": STALK, "pos": Vector2i(0, 1)},
				 {"tile": STALK, "pos": Vector2i(0, 2)},
				 {"tile": STALK, "pos": Vector2i(0, 3)},
				 {"tile": HEAD, "pos": Vector2i(0, 4)}],
				
	"GGG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, 1)},
					  {"tile": STALK, "pos": Vector2i(0, 2)},
				 	  {"tile": STALK, "pos": Vector2i(0, 3)},
					  {"tile": STALK, "pos": Vector2i(0, 4)},
				 	  {"tile": STALK, "pos": Vector2i(0, 5)},
					  {"tile": HEAD, "pos": Vector2i(0, 6)}],
				
	"F": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
			{"tile": RIGHT_TIP, "pos": Vector2i(-1, 0)},
			{"tile": FLOR, "pos": Vector2i(0, 0)},
			{"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
			{"tile": RIGHT_TIP, "pos": Vector2i(2, 0)}],
			
	"FG": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(-1, 0)},
				 {"tile": FLOR, "pos": Vector2i(0, 0)},
				 {"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(2, 0)},
				 {"tile": STALK, "pos": Vector2i(0, 1)},
				 {"tile": STALK, "pos": Vector2i(0, 2)},
				 {"tile": HEAD, "pos": Vector2i(0, 3)}],
				
	"GF": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 {"tile": STALK, "pos": Vector2i(0, 1)},
				 {"tile": LEFT_TIP, "pos": Vector2i(-2, 2)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(-1, 2)},
				 {"tile": FLOR, "pos": Vector2i(0, 2)},
				 {"tile": RIGHT_MID, "pos": Vector2i(1, 2)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(2, 2)}],
				
	"FGG": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(-1, 0)},
					  {"tile": FLOR, "pos": Vector2i(0, 0)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, 0)},
					  {"tile": STALK, "pos": Vector2i(0, 1)},
					  {"tile": STALK, "pos": Vector2i(0, 2)},
					  {"tile": STALK, "pos": Vector2i(0, 3)},
					  {"tile": STALK, "pos": Vector2i(0, 4)},
					  {"tile": HEAD, "pos": Vector2i(0, 5)}],
					
	"GFG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, 1)},
					  {"tile": LEFT_TIP, "pos": Vector2i(-2, 2)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(-1, 2)},
					  {"tile": FLOR, "pos": Vector2i(0, 2)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, 2)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, 2)},
					  {"tile": STALK, "pos": Vector2i(0, 3)},
				 	  {"tile": STALK, "pos": Vector2i(0, 4)},
					  {"tile": HEAD, "pos": Vector2i(0, 5)}],
					
	"GGF": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, 1)},
					  {"tile": STALK, "pos": Vector2i(0, 2)},
				 	  {"tile": STALK, "pos": Vector2i(0, 3)},
					  {"tile": STALK, "pos": Vector2i(0, 4)},
				 	  {"tile": STALK, "pos": Vector2i(0, 5)},
					  {"tile": LEFT_TIP, "pos": Vector2i(-2, 6)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(-1, 6)},
					  {"tile": FLOR, "pos": Vector2i(0, 6)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, 6)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, 6)}]
}

var tile_map: TileMapLayer
var state := []   # e.g. [ "F", "G", "G" ]
var debug_mode := true  # Set to false to disable debug output

func _ready() -> void:
	tile_map = $TileMapLayer
	if not tile_map:
		push_error("TileMapLayer node not found! Please check scene structure.")
		return
		
	print("Vine system initialized at position: ", global_position)
	print("Available input actions: grow (Z), flor (X), grow_u (A), flor_u (S)")
	build_state()

# Handle input using _unhandled_input for best practices
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grow"):
		grow()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flor"):
		flor()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("grow_u"):
		grow_u()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flor_u"):
		flor_u()
		get_viewport().set_input_as_handled()

func grow() -> void:
	if state.count("G") < 3 and len(state) < 3:
		state.push_front("G")
		if debug_mode:
			print("Growing! New state: ", state)
	else:
		if debug_mode:
			print("Cannot grow: Max size reached or too many growth segments")
	build_state()

func flor() -> void:
	if state.count("F") < 1 and len(state) < 3:
		state.push_front("F")
		if debug_mode:
			print("Flowering! New state: ", state)
	else:
		if debug_mode:
			print("Cannot flower: Already has flower or too many segments")
	build_state()

func grow_u() -> void:
	var had_growth = state.has("G")
	state.erase("G")
	if debug_mode:
		if had_growth:
			print("Growth removed! New state: ", state)
		else:
			print("No growth to remove")
	build_state()

func flor_u() -> void:
	var had_flower = state.has("F")
	state.erase("F")
	if debug_mode:
		if had_flower:
			print("Flower removed! New state: ", state)
		else:
			print("No flower to remove")
	build_state()

func build_state() -> void:
	if not tile_map:
		push_error("TileMapLayer is null, cannot build state")
		return
		
	# 1) Make a key string like "GFG" or ""
	var state_copy = state.duplicate()
	state_copy.reverse()
	var key = ""
	for s in state_copy:
		key += s          # e.g. ["G","F","G"] → "GFG"

	if debug_mode:
		print("Building state: '", key, "' from state array: ", state)

	# 2) Clear the tilemap
	tile_map.clear()

	# 3) Check if state exists
	if not STATES.has(key):
		push_error("Invalid state key: '" + key + "'. Available states: " + str(STATES.keys()))
		return

	# 4) Stamp out each tile for this state
	var tile_count = 0
	for entry in STATES.get(key, []):
		var cell = BASE_LOC + entry.pos         # world‑grid cell
		var atlas = entry.tile                  # atlas coords
		
		# Godot 4.x API: set_cell(position, source_id, atlas_coords)
		tile_map.set_cell(cell, SOURCE_ID, atlas)
		tile_count += 1
		
		if debug_mode:
			print("  Placed tile at ", cell, " with atlas coords ", atlas)
	
	if debug_mode:
		print("State build complete. Placed ", tile_count, " tiles.")

# Helper function to get current state as string
func get_state_string() -> String:
	var state_copy = state.duplicate()
	state_copy.reverse()
	var key = ""
	for s in state_copy:
		key += s
	return key

# Helper function to reset vine to initial state
func reset_vine() -> void:
	state.clear()
	if debug_mode:
		print("Vine reset to initial state")
	build_state()

# Helper function to set debug mode
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	print("Debug mode ", "enabled" if enabled else "disabled")
