extends Node

# Singleton class for managing mouse cursor appearance and behavior
# This class handles cursor textures, validation, and cursor switching

# Cursor textures
var shovel_cursor_texture : Texture2D
var x_cursor_texture : Texture2D

# Constants
const SHOVEL_IMAGE_HEIGHT = 80

func _ready():
	print("CursorManager singleton ready")
	_load_cursor_textures()
	
	# Set shovel cursor as default
	set_shovel_cursor()

func _load_cursor_textures():
	# Load the shovel texture
	shovel_cursor_texture = load("res://Assets/nomad/shovel.png")
	if not shovel_cursor_texture:
		print("Warning: Could not load shovel.png for custom cursor")
	
	# Load the x cursor texture
	x_cursor_texture = load("res://Assets/x_cursor.png")
	if not x_cursor_texture:
		print("Warning: Could not load x_cursor.png for custom cursor")

func set_shovel_cursor():
	if shovel_cursor_texture:
		Input.set_custom_mouse_cursor(shovel_cursor_texture, Input.CURSOR_ARROW, Vector2(0, SHOVEL_IMAGE_HEIGHT))
		print("Cursor set to shovel")

func set_x_cursor():
	if x_cursor_texture:
		Input.set_custom_mouse_cursor(x_cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))
		print("Cursor set to X")

func check_cursor_position(mouse_pos: Vector2):
	# Check if the position is valid for node placement
	if _is_position_valid_for_placement(mouse_pos):
		set_shovel_cursor()
	else:
		set_x_cursor()

func _is_position_valid_for_placement(pos: Vector2) -> bool:
	# Get the current path from Global
	var placed_nodes = Global.placed_nodes
	
	# Check if we have enough energy to place a node at this position
	if placed_nodes.size() > 0:
		var last_node_pos = placed_nodes[-1].position
		
		# Use the NodePlacementValidator to check if the connection is valid
		var validation = NodePlacementValidator.validate_node_connection(last_node_pos, pos, PlayerEnergy.get_energy())
		if not validation.valid:
			print("Position invalid: ", validation.reason)
			return false
	else:
		# If no selected path, just check if the position itself is valid (obstacles only)
		# Note: We can't check distance from existing nodes here since we don't have access to placed_nodes
		if not NodePlacementValidator.can_place_node_at_position(pos, []):
			print("Position blocked by obstacle")
			return false
	
	print("Position valid for node placement")
	return true
