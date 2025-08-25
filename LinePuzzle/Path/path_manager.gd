class_name PathManager
extends Node2D

# Dynamic node placement system
const PATHNODE_SCENE = preload("res://LinePuzzle/Path/pathnode.tscn")

# Dynamic node management
var selected_node
var placed_nodes = []

# Reference to checkpoint manager
@onready var checkpoint_manager: CheckpointManager = get_parent().get_node_or_null("CheckpointManager")

func _ready():
	print("PathManager _ready() called")
	init_spawn_point()
	# Connect to global level click signal
	Global.level_clicked.connect(handle_level_click)
	# Connect to global right-click signal
	Global.right_clicked.connect(handle_right_click)
	print("PathManager connected to Global.level_clicked and Global.right_clicked signals")

#initialize the spawn point as a node that is part of the selected path
func init_spawn_point():
	# The spawn point is the permanent starting point of the path. It should never be removed from the path and serves as the anchor for all connections
	var spawn_point = get_node_or_null("SpawnPoint")
	if spawn_point != null:
		# Make sure spawn point is visible
		spawn_point.show()
		
		# Create a visual node at spawn point location
		var spawn_node = create_node_at_position(spawn_point.position)
		spawn_point.show_as_spawn_point(spawn_node)
		placed_nodes.append(spawn_node)
		selected_node = spawn_node
		
		# Update global selected path
		Global.update_placed_nodes(placed_nodes)
		
	else:
		print("ERROR: No spawn point found")


# Create a new node at the specified position
func create_node_at_position(pos: Vector2) -> PathNode:
	var pathnode = PATHNODE_SCENE.instantiate()
	pathnode.position = pos
	add_child(pathnode)
	return pathnode


# Handle level clicks from global click handler
func handle_level_click(click_position: Vector2):
	print("PathManager received level click at: ", click_position)
	# First check if we clicked on a checkpoint
	var clicked_checkpoint = get_checkpoint_at_position(click_position)
	if clicked_checkpoint != null:
		print("Clicked on checkpoint: ", clicked_checkpoint.name)
		# Clicked on checkpoint - handle checkpoint logic
		handle_checkpoint_click(clicked_checkpoint)
		return
	
	if node_is_at_position(click_position):
		print("Clicked on existing node")
		# Clicked on existing node - handle selection
		handle_node_placement(get_node_at_position(click_position))
	elif (NodePlacementValidator.can_place_node_at_position(click_position, placed_nodes)):
		place_new_node(click_position)


# Handle right-clicks from global click handler
func handle_right_click(click_position: Vector2):
	print("PathManager received right-click at: ", click_position)
	# Right-click removes the last node from the path, except for the spawn point
	if placed_nodes.size() > 1:
		remove_node_from_path()
	else:
		print("Right-click: cannot remove node - spawn point must remain in path")


# Check if there's a checkpoint at the given position
func get_checkpoint_at_position(pos: Vector2):
	if not checkpoint_manager:
		return null
	
	var checkpoints = checkpoint_manager.get_checkpoints()
	for checkpoint in checkpoints:
		if checkpoint.position.distance_to(pos) < 20:  # Click tolerance
			return checkpoint
	return null

# Check if there's a node at the given position
func node_is_at_position(pos: Vector2) -> bool:
	for node in placed_nodes:
		if node.position.distance_to(pos) < 20:  # Click tolerance
			return true
	return false


# Get the node at the given position
func get_node_at_position(pos: Vector2) -> PathNode:
	for node in placed_nodes:
		if node.position.distance_to(pos) < 20:  # Click tolerance
			return node
	return null




# Handle checkpoint clicks
func handle_checkpoint_click(checkpoint):
	# Check if there's an obstacle at the checkpoint position
	if not NodePlacementValidator.can_place_node_at_position(checkpoint.position, placed_nodes):
		print("Cannot place node at checkpoint - obstacle detected!")
		return
	
	# Find the checkpoint index
	var checkpoint_index = 0
	if checkpoint_manager:
		var checkpoints = checkpoint_manager.get_checkpoints()
		checkpoint_index = checkpoints.find(checkpoint)
		if checkpoint_index == -1:
			checkpoint_index = 0
	
	var checkpoint_name = "checkpoint_" + str(checkpoint_index)
	
	# Validate the connection using NodePlacementValidator
	var validation = NodePlacementValidator.validate_node_connection(selected_node.position, checkpoint.position, PlayerEnergy.get_energy())
	if not validation.valid:
		print("Cannot connect to checkpoint: ", validation.reason)
		return
	
	# Create a visual node at checkpoint location and connect
	var checkpoint_node = create_node_at_position(checkpoint.position)
	checkpoint_node.checkpoint = true
	checkpoint_node.checkpoint_name = checkpoint_name
	
	# Connect the nodes
	connect_nodes(selected_node, checkpoint_node)


# Place a new node at the clicked position
func place_new_node(pos: Vector2):
	print("Creating new node at position: ", pos)	
	
	# Create and place the node
	var new_node = create_node_at_position(pos)
	print("debug, placed new node: " + new_node.name)
	
	print("Node placed! No energy cost.")
	
	# If we have a selected node, connect to it
	if selected_node != null:
		print("Connecting to selected node")
		connect_nodes(selected_node, new_node)
	else:
		print("Starting new path with this node")
		# Start new path with this node
		selected_node = new_node
		placed_nodes = [new_node]
		new_node.make_visible()
		new_node.toggle_selection()
		
		# Update global selected path
		Global.update_placed_nodes(placed_nodes)
		
		draw_node_path()


# Connect two nodes with a path
func connect_nodes(node1: PathNode, node2: PathNode):
	# Validate the connection using NodePlacementValidator
	var validation = NodePlacementValidator.validate_node_connection(node1.position, node2.position, PlayerEnergy.get_energy())
	if not validation.valid:
		print("Cannot connect nodes: ", validation.reason)
		return
	
	# Add to path
	placed_nodes.append(node2)
	selected_node = node2
	node2.make_visible()
	node2.toggle_selection()
		
	# Update global selected path
	Global.update_placed_nodes(placed_nodes)
		
	# Decrease energy
	PlayerEnergy.decrease_energy(validation.energy_cost)
	print("Nodes connected! Energy decreased by ", validation.energy_cost, ". Remaining energy: ", PlayerEnergy.get_energy())
	
	# Check if the added node is a checkpoint and emit signal
	if checkpoint_manager and checkpoint_manager.is_checkpoint(node2):
		checkpoint_manager.checkpoint_reached.emit(checkpoint_manager.get_checkpoint_name(node2))
	
	# Draw the path
	draw_node_path()


# Handle selection of existing nodes
func handle_node_placement(node: PathNode):
#TODO: this check should be done next to the check for
# the line being drawn. Or at least, try to put those two checks together.

	# Check if the node is on an obstacle
	if not NodePlacementValidator.can_place_node_at_position(node.position, placed_nodes):
		print("Cannot select node - it's on an obstacle!")
		return
	
	if selected_node == null:
		# Start new path
		selected_node = node
		placed_nodes = [node]
		node.make_visible()
		node.toggle_selection()
		
		# Update global selected path
		Global.update_placed_nodes(placed_nodes)
		
		# Check if the selected node is a checkpoint and emit signal
		if checkpoint_manager and checkpoint_manager.is_checkpoint(node):
			checkpoint_manager.checkpoint_reached.emit(checkpoint_manager.get_checkpoint_name(node))
		
		# Draw the path (single node, no lines)
		draw_node_path()
	else:
		# Validate the connection using NodePlacementValidator
		var validation = NodePlacementValidator.validate_node_connection(selected_node.position, node.position, PlayerEnergy.get_energy())
		if not validation.valid:
			print("Cannot connect to node: ", validation.reason)
			return
		connect_nodes(selected_node, node)


# TODO: there is a lot of redundant code here. remove the unnecessary branches.
func remove_node_from_path():
	if (not checkpoint_manager):
		print("No checkpoint manager found")
		return

	# Calculate the distance of the line segment being removed
	var removed_node = selected_node
	var previous_node = placed_nodes[placed_nodes.size() - 2]
		
	# For checkpoint nodes, we need to handle them specially
	# The PathNode gets removed, but the actual checkpoint remains
	if removed_node.checkpoint == true:
		checkpoint_manager.checkpoint_reset.emit(removed_node.checkpoint_name)
		print("Emitted checkpoint reset signal for: ", removed_node.checkpoint_name)

	_update_energy_for_node_removal(previous_node, removed_node)	
	

	placed_nodes.pop_back()

	removed_node.queue_free()		

	#select previous node
	selected_node = placed_nodes[placed_nodes.size() - 1]
	selected_node.make_visible()
	selected_node.toggle_selection()

	# Update global selected path
	Global.update_placed_nodes(placed_nodes)
	
	print("New selected node: ", selected_node.name, " at position: ", selected_node.position)
	
	# Redraw the path after removing the node
	draw_node_path()


# Increase energy based on the distance of the removed line segment (if there was a previous node)
func _update_energy_for_node_removal(previous_node, removed_node):
	var distance = NodePlacementValidator.get_connection_energy_cost(previous_node.position, removed_node.position)
	PlayerEnergy.increase_energy(distance)
	print("Energy increased by ", distance, ". Current energy: ", PlayerEnergy.get_energy())


# Draw the path between selected nodes
func draw_node_path():
	# Clear existing path lines
	for child in get_children():
		if child is Line2D:
			child.queue_free()
	
	# Only draw lines if we have more than one node in the path
	if placed_nodes.size() > 1:
		for i in range(placed_nodes.size() - 1):
			var line = Line2D.new()
			line.points = [placed_nodes[i].position, placed_nodes[i + 1].position]
			line.width = 3.0
			line.default_color = Color.WHITE
			add_child(line)
