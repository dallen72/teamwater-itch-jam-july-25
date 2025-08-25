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


func set_x_cursor():
	if x_cursor_texture:
		Input.set_custom_mouse_cursor(x_cursor_texture, Input.CURSOR_ARROW, Vector2(16, 16))


func start_cursor_check_timer():
	# Create a timer to check cursor position periodically
	var timer = Timer.new()
	timer.name = "CursorCheckTimer"
	timer.wait_time = 0.1  # Check every 100ms
	timer.timeout.connect(_check_cursor_position)
	add_child(timer)
	timer.start()
	print("Cursor check timer started")


func _check_cursor_position():
	# Get current mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Validate the position using NodePlacementValidator
	var is_valid = NodePlacementValidator.can_place_node_at_position(mouse_pos, Global.placed_nodes)
	# Tell CursorManager what cursor to show
	CursorManager.set_cursor_for_position_validity(is_valid)



func set_cursor_for_position_validity(is_valid: bool):
	# Set cursor based on whether the position is valid for node placement.	
	# also, if the winpopup ui is visible, set the cursor to the shovel
	if is_valid or (get_tree().get_root().get_node("Level/WinPopupUI").visible == true):
		set_shovel_cursor()
	else:
		set_x_cursor()
