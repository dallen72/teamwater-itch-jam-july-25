
extends Node2D

const PathNode = preload("res://LinePuzzle/pathnode.gd")

# Signal for checkpoint clicks
signal checkpoint_clicked(checkpoint)

# Click area for checkpoint interaction
var click_area: Area2D
var collision_shape: CollisionShape2D
var checkpoint_id: int = -1
var checkpoint_name: String = ""

func _ready():
	add_to_group("CheckPoint")
	setup_click_area()
	print("Checkpoint added to group CheckPoint")

func setup_click_area():
	# Create click area for interaction
	click_area = Area2D.new()
	add_child(click_area)
	
	# Add collision shape
	collision_shape = CollisionShape2D.new()
	click_area.add_child(collision_shape)
	
	# Set up collision shape (adjust size as needed)
	var shape = CircleShape2D.new()
	shape.radius = 20.0  # Adjust this value for click area size
	collision_shape.shape = shape
	
	# Connect input event
	click_area.input_event.connect(_on_click_area_input_event)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Handle checkpoint click
		handle_checkpoint_click()

func handle_checkpoint_click():
	# Emit signal to notify the path system
	checkpoint_clicked.emit(self)

# Takes a path node (PathNode instance) and sets it up as a checkpoint
func show_closest_node_as_checkpoint(node: PathNode, id: int) -> void:
	checkpoint_id = id
	checkpoint_name = "checkpoint_" + str(id)
	
	node.checkpoint = true
	node.checkpoint_id = id
	node.checkpoint_name = checkpoint_name
	
	# Make the checkpoint visible with green color
	node.make_visible()
	if node.has_node("VisibleShape"):
		node.get_node("VisibleShape").color = Color.GREEN 
