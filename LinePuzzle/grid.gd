extends Node2D

# Signal emitted when a checkpoint is reached
signal checkpoint_reached(checkpoint_name)
# Signal emitted when a checkpoint is reset (unselected)
signal checkpoint_reset(checkpoint_name)

# Grid configuration
const GRID_SIZE = 10
const PATHNODE_SCENE = preload("res://LinePuzzle/pathnode.tscn")

# Grid data structure
var grid_nodes = []
var selected_node
var grid_height = 500

# the path is a stack of nodes, with the top node being the last node added
var selected_path = []
# a dict of nodes that the selected path visibly traverses
var nodes_along_selected_path = []
# Track which checkpoints have been reached
var reached_checkpoints = {}

# Energy system integration - PlayerEnergy is now a global singleton

func _ready():
	generate_grid()
	init_spawn_point()
	# Wait a frame to ensure all nodes are properly initialized
	await get_tree().process_frame
	init_checkpoints()
	# Connect to energy depleted signal
	PlayerEnergy.energy_depleted.connect(_on_energy_depleted)
	# Debug: Show initial energy
	print("Initial player energy: ", PlayerEnergy.get_energy())


func init_spawn_point():
	var spawn_point = get_node_or_null("SpawnPoint")
	if spawn_point != null:
		var true_spawn_point = get_closest_node(spawn_point.position)
		spawn_point.show_closest_node_as_spawn_point(true_spawn_point)
		selected_path.append(true_spawn_point)
		selected_node = true_spawn_point
	else:
		print("ERROR: No spawn point found")


func init_checkpoints():
	var checkpoints = get_tree().get_nodes_in_group("CheckPoint")
	print("Found ", checkpoints.size(), " checkpoints in group")
	
	# Fallback: if no checkpoints found in group, try to find them by name
	if checkpoints.size() == 0:
		checkpoints = []
		for child in get_children():
			if "CheckPoint" in child.name:
				checkpoints.append(child)
				print("Found checkpoint by name: ", child.name)
	
	if checkpoints.size() > 0:
		for i in range(checkpoints.size()):
			var checkpoint = checkpoints[i]
			print("Processing checkpoint ", i, " at position ", checkpoint.position)
			var true_checkpoint = get_closest_node(checkpoint.position)
			if true_checkpoint != null:
				print("Setting up checkpoint ", i, " on node at ", true_checkpoint.position)
				checkpoint.show_closest_node_as_checkpoint(true_checkpoint, i)
			else:
				print("ERROR: Could not find closest node for checkpoint ", i)
		checkpoint_reached.connect(_on_checkpoint_reached)
		checkpoint_reset.connect(_on_checkpoint_reset)
		# Initialize checkpoint tracking
		reached_checkpoints = {}
		for i in range(checkpoints.size()):
			reached_checkpoints["checkpoint_" + str(i)] = false
		print("Initialized checkpoint tracking for ", reached_checkpoints.size(), " checkpoints")
	else:
		print("ERROR: No checkpoints found")



func generate_grid():
	# Calculate spacing between nodes
	@warning_ignore("integer_division")
	var spacing = grid_height / (GRID_SIZE - 1)
	
	var LEFT_MARGIN = 500
	var TOP_MARGIN = 350
	# Calculate starting position to center the grid
	var start_x = -spacing * (GRID_SIZE - 1) * 0.5 + LEFT_MARGIN
	var start_y = -grid_height * 0.5 + TOP_MARGIN
	
	# Generate grid positions and create nodes
	for row in range(GRID_SIZE):
		grid_nodes.append([])
		for col in range(GRID_SIZE):
			var pos = Vector2(
				start_x + col * spacing,
				start_y + row * spacing
			)
			
			# Create PathNode instance
			var pathnode = PATHNODE_SCENE.instantiate()
			pathnode.position = pos
			add_child(pathnode)
			
			# Store reference in grid array
			grid_nodes[row].append(pathnode)
	
	print("Grid generated with ", GRID_SIZE * GRID_SIZE, " nodes")
	print("Grid dimensions: ", GRID_SIZE, "x", GRID_SIZE)
	print("Grid height: ", grid_height, " pixels")
	print("Node spacing: ", spacing, " pixels")






# when the mouse is clicked on the node within the click area, toggle the selection
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handleNodeSelection(event.position)
		

# selected the node, then re-draws the path that the selected path makes
func handleNodeSelection(event_pos):
	var closest_node = get_closest_node(event_pos)
	if (selected_node == null):
		select_new_node(closest_node)
	else:
		if (not new_path_segment_obstructed(closest_node)):
			if (closest_node == selected_node and selected_path.size() > 1):
				remove_node_from_path()
			elif (node_intersects_selected_path(closest_node)):
				return
			else:
				# Check if we have enough energy to add this node to the path
				var distance = selected_node.position.distance_to(closest_node.position)
				if not PlayerEnergy.can_decrease_energy(distance):
					print("Not enough energy! Need ", distance, " but only have ", PlayerEnergy.get_energy())
					return
				select_new_node(closest_node)	
			drawNodePath()
			calculate_nodes_along_selected_path()


func node_intersects_selected_path(node):
	return nodes_along_selected_path.has(node)


# for every node in the selected path, find the raycast between the node and the next node in the path
# if the raycast intersects with a node in the grid, add it to the nodes_along_selected_path dict
func calculate_nodes_along_selected_path():
	var space_state = get_world_2d().direct_space_state
	# iterate through every node in the selected_path
	for i in range(selected_path.size() - 1):
		nodes_along_selected_path.append(selected_path[i])
	for i in range(selected_path.size() - 1):
		var node1 = selected_path[i]
		var node2 = selected_path[i + 1]
		var query = PhysicsRayQueryParameters2D.create(node1.position, node2.position)
		var result = space_state.intersect_ray(query)
		if (result.size() > 0):
			# for every thing in the result, if it belongs to the GridNode group, add it to the nodes_along_selected_path dict
			for thing in result:
				if (thing.collider.is_in_group("GridNode")):
					nodes_along_selected_path.append(thing.collider)


func remove_node_from_path():
	# Calculate the distance of the line segment being removed
	var removed_node = selected_node
	var previous_node = selected_path[selected_path.size() - 2] if selected_path.size() > 1 else null
	
	selected_node.make_invisible()
	selected_node.toggle_selection()
	selected_path.remove_at(selected_path.size() - 1)
	
	# Restore checkpoint appearance if the removed node was a checkpoint
	if removed_node.checkpoint:
		removed_node.restore_checkpoint_appearance()
		# Emit checkpoint reset signal to update tracking
		checkpoint_reset.emit(removed_node.checkpoint_name)
	
	# Increase energy based on the distance of the removed line segment
	if previous_node != null:
		var distance = previous_node.position.distance_to(removed_node.position)
		PlayerEnergy.increase_energy(distance)
		print("Energy increased by ", distance, ". Current energy: ", PlayerEnergy.get_energy())
	
	if (selected_path.size() == 0):
		selected_node = null
	else:
		selected_node = selected_path[selected_path.size() - 1]
		selected_node.make_visible()
		selected_node.toggle_selection()


# iterate through the selected path and draw a line between each node
func drawNodePath():
	for child in $PathLines.get_children():
		child.queue_free()
		await child.tree_exited
	for i in range(selected_path.size() - 1):
		var line = Line2D.new()
		line.points = [selected_path[i].position, selected_path[i + 1].position]
		$PathLines.add_child(line)


# selects the node closest to where is clicked, or toggles the selected node to unselected
func select_new_node(closest_node):
	if (selected_node != null):
		selected_node.make_invisible()
		selected_node.toggle_selection()
		
		# Restore checkpoint appearance if the deselected node was a checkpoint
		if selected_node.checkpoint:
			selected_node.restore_checkpoint_appearance()
		
		# Decrease energy based on the distance to the new node
		var distance = selected_node.position.distance_to(closest_node.position)
		PlayerEnergy.decrease_energy(distance)
		print("Energy decreased by ", distance, ". Remaining energy: ", PlayerEnergy.get_energy())
	
	selected_node = closest_node
	selected_path.append(selected_node)
	selected_node.make_visible()
	selected_node.toggle_selection()

	# Check if the added node is a checkpoint and emit signal
	if selected_node.checkpoint:
		checkpoint_reached.emit(selected_node.checkpoint_name)
			
# if the new node is in the area of an obstacle, return true. obstaces are defined by collision.
func new_path_segment_obstructed(closest_node):
	var space_state = get_world_2d().direct_space_state
	# use global coordinates, not local to node
	var query = PhysicsRayQueryParameters2D.create(selected_node.position, closest_node.position)
	var result = space_state.intersect_ray(query)
	if (result.size() > 0):
		return true
	return false


func get_closest_node(click_pos):
	var closest_node = null
	var closest_distance = 1000000
	for row in grid_nodes:
		for node in row:
			var distance = click_pos.distance_to(node.position)
			if distance < closest_distance:
				closest_distance = distance
				closest_node = node
	return closest_node


# Called when energy is depleted
func _on_energy_depleted():
	print("Energy depleted! Cannot draw more paths.")
	# You could add visual feedback here, like disabling node selection
	# or showing a game over message


# Called when a checkpoint is reached
func _on_checkpoint_reached(_checkpoint_name):
	# Mark this checkpoint as reached
	if reached_checkpoints.has(_checkpoint_name):
		reached_checkpoints[_checkpoint_name] = true
		print("Checkpoint reached: ", _checkpoint_name)
		
		# Check if all checkpoints have been reached
		var all_reached = true
		for checkpoint in reached_checkpoints.values():
			if not checkpoint:
				all_reached = false
				break
		
		# Show win popup only when all checkpoints are reached
		if all_reached:
			print("All checkpoints reached! Level complete!")
			$WinPopupUI.show()
		else:
			print("Checkpoint reached! ", reached_checkpoints.size() - reached_checkpoints.values().count(false), " of ", reached_checkpoints.size(), " checkpoints completed.")

# Called when a checkpoint is reset (unselected)
func _on_checkpoint_reset(_checkpoint_name):
	# Mark this checkpoint as unreached
	if reached_checkpoints.has(_checkpoint_name):
		reached_checkpoints[_checkpoint_name] = false
		print("Checkpoint reset: ", _checkpoint_name)
		
		# Update progress display
		var completed_count = reached_checkpoints.size() - reached_checkpoints.values().count(false)
		print("Checkpoint progress: ", completed_count, " of ", reached_checkpoints.size(), " checkpoints completed.")


# Get the energy cost for a potential path to a node
func get_path_energy_cost(target_node):
	if selected_node == null:
		return 0
	return selected_node.position.distance_to(target_node.position)
