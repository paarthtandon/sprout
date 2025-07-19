extends Area2D

# Exported variable to control maximum number of runes (state items)
@export var max_runes: int = 3

const BASE_LOC = Vector2i(0, 0) # base location in scene
const SOURCE_ID = 2  # Correct source ID from tileset.tres

# Tile atlas coordinates
const BABY = Vector2i(16, 2)
const STALK = Vector2i(17, 2)
const HEAD = Vector2i(18, 2)
const LEFT_TIP = Vector2i(19, 2)
const LEFT_MID = Vector2i(20, 2)
const FLOR = Vector2i(21, 2)
const FLOR_INT = Vector2i(24, 2)
const RIGHT_MID = Vector2i(22, 2)
const RIGHT_TIP = Vector2i(23, 2)

const STATES = {
	"": [{"tile": BABY, "pos": Vector2i(0, 0)}],
	
	"G": [{"tile": STALK, "pos": Vector2i(0, 0)},
			{"tile": STALK, "pos": Vector2i(0, -1)},
			{"tile": HEAD, "pos": Vector2i(0, -2)}],
			
	"GG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 {"tile": STALK, "pos": Vector2i(0, -1)},
				 {"tile": STALK, "pos": Vector2i(0, -2)},
				 {"tile": STALK, "pos": Vector2i(0, -3)},
				 {"tile": HEAD, "pos": Vector2i(0, -4)}],
				
	"GGG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, -1)},
					  {"tile": STALK, "pos": Vector2i(0, -2)},
				 	  {"tile": STALK, "pos": Vector2i(0, -3)},
					  {"tile": STALK, "pos": Vector2i(0, -4)},
				 	  {"tile": STALK, "pos": Vector2i(0, -5)},
					  {"tile": HEAD, "pos": Vector2i(0, -6)}],
				
	"F": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
			{"tile": LEFT_MID, "pos": Vector2i(-1, 0)},
			{"tile": FLOR, "pos": Vector2i(0, 0)},
			{"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
			{"tile": RIGHT_TIP, "pos": Vector2i(2, 0)}],
			
	"FG": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
				 {"tile": LEFT_MID, "pos": Vector2i(-1, 0)},
				 {"tile": FLOR_INT, "pos": Vector2i(0, 0)},
				 {"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(2, 0)},
				 {"tile": STALK, "pos": Vector2i(0, -1)},
				 {"tile": STALK, "pos": Vector2i(0, -2)},
				 {"tile": HEAD, "pos": Vector2i(0, -3)}],
				
	"GF": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 {"tile": STALK, "pos": Vector2i(0, -1)},
				 {"tile": LEFT_TIP, "pos": Vector2i(-2, -2)},
				 {"tile": LEFT_MID, "pos": Vector2i(-1, -2)},
				 {"tile": FLOR, "pos": Vector2i(0, -2)},
				 {"tile": RIGHT_MID, "pos": Vector2i(1, -2)},
				 {"tile": RIGHT_TIP, "pos": Vector2i(2, -2)}],
				
	"FGG": [{"tile": LEFT_TIP, "pos": Vector2i(-2, 0)},
					  {"tile": LEFT_MID, "pos": Vector2i(-1, 0)},
					  {"tile": FLOR_INT, "pos": Vector2i(0, 0)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, 0)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, 0)},
					  {"tile": STALK, "pos": Vector2i(0, -1)},
					  {"tile": STALK, "pos": Vector2i(0, -2)},
					  {"tile": STALK, "pos": Vector2i(0, -3)},
					  {"tile": STALK, "pos": Vector2i(0, -4)},
					  {"tile": HEAD, "pos": Vector2i(0, -5)}],
					
	"GFG": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, -1)},
					  {"tile": LEFT_TIP, "pos": Vector2i(-2, -2)},
					  {"tile": LEFT_MID, "pos": Vector2i(-1, -2)},
					  {"tile": FLOR_INT, "pos": Vector2i(0, -2)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, -2)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, -2)},
					  {"tile": STALK, "pos": Vector2i(0, -3)},
					  {"tile": HEAD, "pos": Vector2i(0, -4)}],
					
	"GGF": [{"tile": STALK, "pos": Vector2i(0, 0)},
				 	  {"tile": STALK, "pos": Vector2i(0, -1)},
					  {"tile": STALK, "pos": Vector2i(0, -2)},
				 	  {"tile": STALK, "pos": Vector2i(0, -3)},
					  {"tile": LEFT_TIP, "pos": Vector2i(-2, -4)},
					  {"tile": LEFT_MID, "pos": Vector2i(-1, -4)},
					  {"tile": FLOR, "pos": Vector2i(0, -4)},
					  {"tile": RIGHT_MID, "pos": Vector2i(1, -4)},
					  {"tile": RIGHT_TIP, "pos": Vector2i(2, -4)}]
}

var tile_map: TileMapLayer
var state_v := []   # e.g. [ "F", "G", "G" ]
var debug_mode := true  # Set to false to disable debug output
var rune_ui: Node2D  # Reference to the rune UI component

func _ready() -> void:
	tile_map = $TileMapLayer
	if not tile_map:
		push_error("TileMapLayer node not found! Please check scene structure.")
		return
	
	# Find the rune UI component
	rune_ui = $RuneUI
	if not rune_ui:
		print("RuneUI not found - rune display will not be available")
	
	# Add this vine to the plants group for proximity detection
	add_to_group("plants")
		
	# print("Vine system initialized at position: ", global_position)
	# print("Available input actions: grow (Z), flor (X), grow_u (A), flor_u (S)")
	# print("NOTE: Player must be within range to control this plant")
	build_state_v()

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
	if state_v.count("G") < 3 and len(state_v) < max_runes:
		state_v.push_front("G")
		# if debug_mode:
			# print("Growing! New state_v: ", state_v)
	# else:
		# if debug_mode:
			# print("Cannot grow: Max size reached or too many growth segments")
	build_state_v()

func flor() -> void:
	if state_v.count("F") < 1 and len(state_v) < max_runes:
		state_v.push_front("F")
		# if debug_mode:
			# print("Flowering! New state_v: ", state_v)
	# else:
		# if debug_mode:
			# print("Cannot flower: Already has flower or too many segments")
	build_state_v()

func grow_u() -> void:
	var had_growth = state_v.has("G")
	state_v.erase("G")
	# if debug_mode:
		# if had_growth:
			# print("Growth removed! New state_v: ", state_v)
		# else:
			# print("No growth to remove")
	build_state_v()

func flor_u() -> void:
	var had_flower = state_v.has("F")
	state_v.erase("F")
	# if debug_mode:
		# if had_flower:
			# print("Flower removed! New state_v: ", state_v)
		# else:
			# print("No flower to remove")
	build_state_v()

func build_state_v() -> void:
	if not tile_map:
		push_error("TileMapLayer is null, cannot build state_v")
		return
		
	# 1) Make a key string like "GFG" or ""
	var state_v_copy = state_v.duplicate()
	state_v_copy.reverse()
	var key = ""
	for s in state_v_copy:
		key += s          # e.g. ["G","F","G"] → "GFG"

	# if debug_mode:
		# print("Building state_v: '", key, "' from state_v array: ", state_v)

	# 2) Clear the tilemap
	tile_map.clear()

	# 3) Check if state_v exists
	if not STATES.has(key):
		push_error("Invalid state_v key: '" + key + "'. Available state_vs: " + str(STATES.keys()))
		return

	# 4) Stamp out each tile for this state_v
	var tile_count = 0
	for entry in STATES.get(key, []):
		var cell = BASE_LOC + entry.pos         # world‑grid cell
		var atlas = entry.tile                  # atlas coords
		
		# set_cell(position, source_id, atlas_coords)
		tile_map.set_cell(cell, SOURCE_ID, atlas)
		tile_count += 1
		
		# if debug_mode:
			# print("  Placed tile at ", cell, " with atlas coords ", atlas)
	
	# if debug_mode:
		# print("State build complete. Placed ", tile_count, " tiles.")
	
	# Notify UI of state change
	_notify_ui_update()

# Helper function to get current state_v as string
func get_state_v_string() -> String:
	var state_v_copy = state_v.duplicate()
	state_v_copy.reverse()
	var key = ""
	for s in state_v_copy:
		key += s
	return key

# Helper function to reset vine to initial state_v
func reset() -> void:
	state_v.clear()
	# if debug_mode:
		# print("Vine reset to initial state_v")
	build_state_v()

# Clear all runes (same as reset)
func clear_runes() -> void:
	state_v.clear()
	if debug_mode:
		print("All runes cleared from vine!")
	build_state_v()

# Notify UI of state changes
func _notify_ui_update() -> void:
	if rune_ui and rune_ui.has_method("update_display"):
		rune_ui.update_display()

# Helper function to set debug mode
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	# print("Debug mode ", "enabled" if enabled else "disabled")
