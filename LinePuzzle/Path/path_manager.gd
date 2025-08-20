class_name PathManager
extends Node2D

# Dynamic node placement system
const PATHNODE_SCENE = preload("res://LinePuzzle/Path/pathnode.tscn")

# Dynamic node management
var placed_nodes = []
var selected_node
var selected_path = []
var nodes_along_selected_path = []

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
		selected_path.append(spawn_node)
		selected_node = spawn_node
		placed_nodes.append(spawn_node)
		
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
		handle_node_selection(get_node_at_position(click_position))
	elif (not is_obstacle_at_position(click_position)):
		place_new_node(click_position)


# Handle right-clicks from global click handler
func handle_right_click(click_position: Vector2):
	print("PathManager received right-click at: ", click_position)
	# Right-click removes the last node from the path, except for the spawn point
	if selected_path.size() > 1:
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

# Check if there's an obstacle at the given position
func is_obstacle_at_position(pos: Vector2) -> bool:
	# Get the parent node (which should be the level root)
	var level_root = get_parent()
	if not level_root:
		return false
	
	# Check for Tree nodes
	var trees = level_root.get_tree().get_nodes_in_group("Tree")
	for tree in trees:
		if tree.position.distance_to(pos) < 75:  # Tree collision radius
			return true
	
	# Check for Cow nodes  
	var cows = level_root.get_tree().get_nodes_in_group("Cow")
	for cow in cows:
		if cow.position.distance_to(pos) < 75:  # Cow collision radius
			return true
	
	return false

# Check if a line between two points intersects with obstacles using raycasts
func path_intersects_obstacles(start_pos: Vector2, end_pos: Vector2) -> bool:
	print("Raycast from ", start_pos, " to ", end_pos)
	
	# Get the physics space for raycasting
	var space_state = get_world_2d().direct_space_state
	
	# Create raycast parameters
	var query = PhysicsRayQueryParameters2D.new()
	query.from = start_pos
	query.to = end_pos
	query.collision_mask = 1  # Use collision layer 1 for obstacles
	
	# Perform the raycast
	var result = space_state.intersect_ray(query)
	
	# If we hit something, check if it's a tree or cow
	if result:
		var collider = result["collider"]
		if collider:
			# Check if the collider is a tree or cow
			if "Tree" in collider.name or "Cow" in collider.name:
				print("Raycast hit obstacle: ", collider.name)
				return true
			else:
				print("Raycast hit non-obstacle: ", collider.name)
	else:
		print("Raycast hit nothing")
	
	return false

# Alternative raycast method that checks multiple points along the path
func path_intersects_obstacles_alternative(start_pos: Vector2, end_pos: Vector2) -> bool:
	print("Alternative raycast from ", start_pos, " to ", end_pos)
	
	var space_state = get_world_2d().direct_space_state
	
	# Check multiple points along the line for more accuracy
	var num_checks = 8
	for i in range(num_checks + 1):
		var t = float(i) / float(num_checks)
		var check_pos = start_pos.lerp(end_pos, t)
		
		# Cast a short ray from the previous point to this point
		var prev_pos = start_pos.lerp(end_pos, max(0, t - 1.0/num_checks))
		
		var query = PhysicsRayQueryParameters2D.new()
		query.from = prev_pos
		query.to = check_pos
		query.collision_mask = 1
		
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result["collider"]
			if collider and ("Tree" in collider.name or "Cow" in collider.name):
				print("Alternative raycast hit obstacle: ", collider.name, " at segment ", i)
				return true
	
	print("Alternative raycast hit nothing")
	return false


# Handle checkpoint clicks
func handle_checkpoint_click(checkpoint):
	# Check if there's an obstacle at the checkpoint position
	if is_obstacle_at_position(checkpoint.position):
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
	

	# Check if we have enough energy to connect
	var distance = selected_node.position.distance_to(checkpoint.position)
	if PlayerEnergy.get_energy() < distance:
		print("Not enough energy! Need ", distance, " but only have ", PlayerEnergy.get_energy())
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
	placed_nodes.append(new_node)
	
	print("Node placed! No energy cost.")
	
	# If we have a selected node, connect to it
	if selected_node != null:
		print("Connecting to selected node")
		connect_nodes(selected_node, new_node)
	else:
		print("Starting new path with this node")
		# Start new path with this node
		selected_node = new_node
		selected_path = [new_node]
		new_node.make_visible()
		new_node.toggle_selection()
		draw_node_path()
		calculate_nodes_along_selected_path()


# Connect two nodes with a path
func connect_nodes(node1: PathNode, node2: PathNode):
	var distance = node1.position.distance_to(node2.position)
	var energy_cost = distance
	
	if PlayerEnergy.get_energy() < energy_cost:
		print("Not enough energy to connect nodes! Need ", energy_cost, " but only have ", PlayerEnergy.get_energy())
		return
	
	# Check if the path goes through any obstacles using the more accurate raycast method
	if path_intersects_obstacles_alternative(node1.position, node2.position):
		print("Cannot connect nodes - path intersects with obstacle!")
		return
	
	# Add to path
	selected_path.append(node2)
	selected_node = node2
	node2.make_visible()
	node2.toggle_selection()
	
	# Decrease energy
	PlayerEnergy.decrease_energy(energy_cost)
	print("Nodes connected! Energy decreased by ", energy_cost, ". Remaining energy: ", PlayerEnergy.get_energy())
	
	# Check if the added node is a checkpoint and emit signal
	if checkpoint_manager and checkpoint_manager.is_checkpoint(node2):
		checkpoint_manager.checkpoint_reached.emit(checkpoint_manager.get_checkpoint_name(node2))
	
	# Draw the path
	draw_node_path()
	calculate_nodes_along_selected_path()


# Handle selection of existing nodes
func handle_node_selection(node: PathNode):
#TODO: this check should be done next to the check for
# the line being drawn. Or at least, try to put those two checks together.

	# Check if the node is on an obstacle
	if is_obstacle_at_position(node.position):
		print("Cannot select node - it's on an obstacle!")
		return
	
	if selected_node == null:
		# Start new path
		selected_node = node
		selected_path = [node]
		node.make_visible()
		node.toggle_selection()
		
		# Check if the selected node is a checkpoint and emit signal
		if checkpoint_manager and checkpoint_manager.is_checkpoint(node):
			checkpoint_manager.checkpoint_reached.emit(checkpoint_manager.get_checkpoint_name(node))
		
		# Draw the path (single node, no lines)
		draw_node_path()
		calculate_nodes_along_selected_path()
	else:
		# Continue existing path - no more deselection on click
		if node_intersects_selected_path(node):
			return
		else:
			# Check if we have enough energy to connect
			var distance = selected_node.position.distance_to(node.position)
			if PlayerEnergy.get_energy() < distance:
				print("Not enough energy! Need ", distance, " but only have ", PlayerEnergy.get_energy())
				return
			connect_nodes(selected_node, node)


func node_intersects_selected_path(node):
	return nodes_along_selected_path.has(node)


# Calculate nodes along the selected path
func calculate_nodes_along_selected_path():
	nodes_along_selected_path.clear()
	
	# Add all nodes in the path
	for node in selected_path:
		nodes_along_selected_path.append(node)



# TODO: there is a lot of redundant code here. remove the unnecessary branches.
func remove_node_from_path():
	if (not checkpoint_manager):
		print("No checkpoint manager found")
		return

	# Calculate the distance of the line segment being removed
	var removed_node = selected_node
	var previous_node = selected_path[selected_path.size() - 2]
		
	# For checkpoint nodes, we need to handle them specially
	# The PathNode gets removed, but the actual checkpoint remains
	if removed_node.checkpoint == true:
		checkpoint_manager.checkpoint_reset.emit(removed_node.checkpoint_name)
		print("Emitted checkpoint reset signal for: ", removed_node.checkpoint_name)

	_update_energy_for_node_removal(previous_node, removed_node)	
	
	# Remove the nodes from the scene
	selected_path.remove_at(selected_path.size() - 1)
	placed_nodes.erase(removed_node)
	removed_node.queue_free()
	
	#select previous node
	selected_node = selected_path[selected_path.size() - 1]
	selected_node.make_visible()
	selected_node.toggle_selection()
	print("New selected node: ", selected_node.name, " at position: ", selected_node.position)
	
	# Redraw the path after removing the node
	draw_node_path()
	calculate_nodes_along_selected_path()


# Increase energy based on the distance of the removed line segment (if there was a previous node)
func _update_energy_for_node_removal(previous_node, removed_node):
	var distance = previous_node.position.distance_to(removed_node.position)
	PlayerEnergy.increase_energy(distance)
	print("Energy increased by ", distance, ". Current energy: ", PlayerEnergy.get_energy())


# Draw the path between selected nodes
func draw_node_path():
	# Clear existing path lines
	for child in get_children():
		if child is Line2D:
			child.queue_free()
	
	# Only draw lines if we have more than one node in the path
	if selected_path.size() > 1:
		for i in range(selected_path.size() - 1):
			var line = Line2D.new()
			line.points = [selected_path[i].position, selected_path[i + 1].position]
			line.width = 3.0
			line.default_color = Color.WHITE
			add_child(line)

	# get the river node, then use the function draw_river_path() to draw the river path, using the selected path
	var river_node = get_tree().get_root().get_node("Root").get_node("River")
	
