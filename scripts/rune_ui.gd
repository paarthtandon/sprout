extends Node2D

# Exported tile coordinates for UI elements
@export var ui_source_id: int = 2
@export var empty_slot_tile: Vector2i = Vector2i(30, 0)  # Empty slot tile coordinates
@export var growth_rune_tile: Vector2i = Vector2i(30, 1)  # G rune tile coordinates  
@export var flower_rune_tile: Vector2i = Vector2i(30, 2)  # F rune tile coordinates
@export var slot_spacing: float = 150.0  # Spacing between slots
@export var ui_offset: Vector2 = Vector2(0, 150)  # Offset below plant

# References
var plant_node: Node2D
var player_node: Node2D
var slot_sprites: Array[Sprite2D] = []
var debug_mode: bool = true

# UI state
var is_visible: bool = false
var max_slots: int = 0
var current_runes: Array = []

func _ready() -> void:
	# Find player and plant references
	_find_references()
	
	# Initial setup
	if plant_node:
		_setup_ui()

func _find_references() -> void:
	# Find player in scene
	var scene_root = get_tree().current_scene
	player_node = scene_root.find_child("Player", true, false)
	
	# Plant node is the parent of this UI
	plant_node = get_parent()
	
	if debug_mode and player_node:
		print("Rune UI initialized for ", plant_node.name if plant_node else "unknown plant")

func _setup_ui() -> void:
	if not plant_node:
		return
		
	# Get max runes from plant
	if plant_node.has_method("get") and plant_node.get("max_runes"):
		max_slots = plant_node.get("max_runes")
	else:
		max_slots = 3  # Default fallback
	
	# Create slot sprites
	_create_slot_sprites()
	
	# Hide initially
	set_ui_visible(false)

func _create_slot_sprites() -> void:
	# Clear existing sprites
	for sprite in slot_sprites:
		if sprite:
			sprite.queue_free()
	slot_sprites.clear()
	
	# Create sprites for each slot
	for i in range(max_slots):
		var sprite = Sprite2D.new()
		add_child(sprite)
		
		# Set up atlas texture
		var atlas_texture = AtlasTexture.new()
		var texture = _get_tileset_texture()
		
		if texture:
			atlas_texture.atlas = texture
			atlas_texture.region = _get_tile_region(empty_slot_tile)
			sprite.texture = atlas_texture
		else:
			# Fallback: create a simple colored rectangle
			var fallback_texture = ImageTexture.new()
			var image = Image.create(128, 128, false, Image.FORMAT_RGB8)
			image.fill(Color.CYAN)  # Bright cyan for debugging
			fallback_texture.set_image(image)
			sprite.texture = fallback_texture
			if debug_mode:
				print("Using fallback texture for slot ", i)
		
		# Position sprite
		var x_pos = (i - max_slots / 2.0 + 0.5) * slot_spacing
		sprite.position = Vector2(x_pos, 0)
		
		# Make sure sprite is visible and properly scaled
		sprite.visible = true
		sprite.scale = Vector2(1.5, 1.5)
		
		# Set z-index to ensure it renders on top
		sprite.z_index = 100
		
		slot_sprites.append(sprite)
		
		if debug_mode:
			print("Created slot sprite ", i, " at position ", sprite.position)
			print("  Texture: ", texture)
			print("  Atlas region: ", atlas_texture.region)
			print("  Sprite visible: ", sprite.visible)

func _get_tileset_texture() -> Texture2D:
	# Get the texture from the plant's tileset (assuming it uses the same tileset)
	var tileset = null
	var texture = null
	
	if plant_node and plant_node.has_method("get") and plant_node.get("tile_map"):
		var tile_map = plant_node.get("tile_map")
		if tile_map and tile_map.tile_set:
			tileset = tile_map.tile_set
			
			if debug_mode:
				print("Found tileset: ", tileset)
				print("Available sources: ", tileset.get_source_count())
	
	if tileset and tileset.get_source(ui_source_id):
		var source = tileset.get_source(ui_source_id)
		if source.has_method("get_texture"):
			texture = source.get_texture()
			if debug_mode:
				print("Loaded texture from source ", ui_source_id, ": ", texture)
		else:
			if debug_mode:
				print("Source ", ui_source_id, " doesn't have get_texture method")
	else:
		if debug_mode:
			print("Could not find source ", ui_source_id, " in tileset")
	
	# Fallback: try to load combined_atlas.png directly (source 2)
	if not texture:
		texture = load("res://assets/combined_atlas.png")
		if debug_mode:
			print("Using fallback texture: ", texture)
	
	return texture

func _get_tile_region(tile_coords: Vector2i) -> Rect2:
	# Each tile is 128x128 pixels based on tileset
	return Rect2(tile_coords.x * 128, tile_coords.y * 128, 128, 128)

func _process(_delta: float) -> void:
	if not player_node or not plant_node:
		return
		
	# Check distance to player using the player's interaction range
	var distance = plant_node.global_position.distance_to(player_node.global_position)
	var interaction_range = _get_player_interaction_range()
	var should_be_visible = distance <= interaction_range
	
	if should_be_visible != is_visible:
		set_ui_visible(should_be_visible)
	
	# Update UI position to follow plant
	if is_visible:
		_update_ui_position()

func _get_player_interaction_range() -> float:
	# Get the interaction range from the player
	if player_node and player_node.has_method("get") and player_node.get("plant_interaction_range"):
		return player_node.get("plant_interaction_range")
	
	# Fallback to default value
	return 1000.0

func _update_ui_position() -> void:
	if not plant_node:
		return
		
	# Position UI below the plant in world space
	global_position = plant_node.global_position + ui_offset
	
	#if debug_mode and is_visible:
		#print("UI positioned at world: ", global_position)

func set_ui_visible(visible: bool) -> void:
	is_visible = visible
	self.visible = visible
	
	if visible:
		_update_rune_display()
	
	if debug_mode:
		print("Rune UI ", "shown" if visible else "hidden", " for ", plant_node.name if plant_node else "unknown")

func _update_rune_display() -> void:
	if not plant_node:
		return
		
	# Get current runes from plant
	_get_plant_runes()
	
	# Update each slot sprite
	for i in range(slot_sprites.size()):
		if i < slot_sprites.size() and slot_sprites[i]:
			var sprite = slot_sprites[i]
			var atlas_texture = sprite.texture as AtlasTexture
			
			if i < current_runes.size():
				# Show filled rune
				var rune_type = current_runes[i]
				var tile_coords = _get_rune_tile_coords(rune_type)
				atlas_texture.region = _get_tile_region(tile_coords)
			else:
				# Show empty slot
				atlas_texture.region = _get_tile_region(empty_slot_tile)

func _get_plant_runes() -> void:
	current_runes.clear()
	
	if not plant_node:
		return
	
	# Get runes from vine
	if plant_node.has_method("get") and plant_node.get("state_v") != null:
		var state_v = plant_node.get("state_v")
		if state_v is Array:
			current_runes = state_v.duplicate()
			current_runes.reverse()  # Match display order
	
	# Get runes from mushroom  
	elif plant_node.has_method("get") and plant_node.get("state_m") != null:
		var state_m = plant_node.get("state_m")
		if state_m is Array:
			current_runes = state_m.duplicate()
			current_runes.reverse()  # Match display order

func _get_rune_tile_coords(rune_type: String) -> Vector2i:
	match rune_type:
		"G":
			return growth_rune_tile
		"F":
			return flower_rune_tile
		_:
			return empty_slot_tile

# Called by plants when their state changes
func update_display() -> void:
	if is_visible:
		_update_rune_display()

# Called by plants to force refresh
func refresh_ui() -> void:
	if plant_node:
		_setup_ui()
		if is_visible:
			_update_rune_display() 
