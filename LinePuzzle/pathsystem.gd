extends Node2D

# Signal emitted when a checkpoint is reached
signal checkpoint_reached(checkpoint_name)
# Signal emitted when a checkpoint is reset (unselected)
signal checkpoint_reset(checkpoint_name)

# Dynamic node placement system
const PATHNODE_SCENE = preload("res://LinePuzzle/pathnode.tscn")

# Dynamic node management
var placed_nodes = []
var selected_node
var selected_path = []
var nodes_along_selected_path = []

# Track which checkpoints have been reached
var reached_checkpoints = {}

func _ready():
	init_spawn_point()
	init_checkpoints()
	# Connect to energy depleted signal
	PlayerEnergy.energy_depleted.connect(_on_energy_depleted)
	# Connect to global level click signal
	Global.level_clicked.connect(handle_level_click)
	# Debug: Show initial energy
	print("Initial player energy: ", PlayerEnergy.get_energy())

func init_spawn_point():
	var spawn_point = get_node_or_null("SpawnPoint")
	if spawn_point != null:
		# Create a visual node at spawn point location
		var spawn_node = create_node_at_position(spawn_point.position)
		spawn_point.show_as_spawn_point(spawn_node)
		selected_path.append(spawn_node)
		selected_node = spawn_node
		placed_nodes.append(spawn_node)
		
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
			# Create a visual node at checkpoint location
			var checkpoint_node = create_node_at_position(checkpoint.position)
			checkpoint.show_closest_node_as_checkpoint(checkpoint_node, i)
			placed_nodes.append(checkpoint_node)
			
			# Connect to checkpoint click signal
			checkpoint.checkpoint_clicked.connect(_on_checkpoint_clicked)
		
		checkpoint_reached.connect(_on_checkpoint_reached)
		checkpoint_reset.connect(_on_checkpoint_reset)
		# Initialize checkpoint tracking
		reached_checkpoints = {}
		for i in range(checkpoints.size()):
			reached_checkpoints["checkpoint_" + str(i)] = false
		print("Initialized checkpoint tracking for ", reached_checkpoints.size(), " checkpoints")
	else:
		print("ERROR: No checkpoints found")

# Handle spawn point clicks
func _on_spawn_point_clicked(spawn_point):
	print("Spawn point clicked!")
	# Handle spawn point logic here if needed

# Handle checkpoint clicks
func _on_checkpoint_clicked(checkpoint):
	print("Checkpoint clicked: ", checkpoint.checkpoint_name)
	# Handle checkpoint logic here if needed

# Create a new node at the specified position
func create_node_at_position(pos: Vector2) -> PathNode:
	var pathnode = PATHNODE_SCENE.instantiate()
	pathnode.position = pos
	add_child(pathnode)
	return pathnode

# Handle level clicks from global click handler
func handle_level_click(click_position: Vector2):
	# Check if we clicked on an existing node
	var clicked_node = get_node_at_position(click_position)
	
	if clicked_node != null:
		# Clicked on existing node - handle selection
		handle_node_selection(clicked_node)
	else:
		# Clicked on empty space - place new node
		place_new_node(click_position)

# Check if there's a node at the given position
func get_node_at_position(pos: Vector2) -> PathNode:
	for node in placed_nodes:
		if node.position.distance_to(pos) < 20:  # Click tolerance
			return node
	return null

# Place a new node at the clicked position
func place_new_node(pos: Vector2):
	# Create and place the node
	var new_node = create_node_at_position(pos)
	placed_nodes.append(new_node)
	
	print("Node placed! No energy cost.")
	
	# If we have a selected node, connect to it
	if selected_node != null:
		connect_nodes(selected_node, new_node)
	else:
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
	
	# Add to path
	selected_path.append(node2)
	selected_node = node2
	node2.make_visible()
	node2.toggle_selection()
	
	# Decrease energy
	PlayerEnergy.decrease_energy(energy_cost)
	print("Nodes connected! Energy decreased by ", energy_cost, ". Remaining energy: ", PlayerEnergy.get_energy())
	
	# Check if the added node is a checkpoint and emit signal
	if node2.checkpoint:
		checkpoint_reached.emit(node2.checkpoint_name)
	
	# Draw the path
	draw_node_path()
	calculate_nodes_along_selected_path()

# Handle selection of existing nodes
func handle_node_selection(node: PathNode):
	if selected_node == null:
		# Start new path
		selected_node = node
		selected_path = [node]
		node.make_visible()
		node.toggle_selection()
		
		# Check if the selected node is a checkpoint and emit signal
		if node.checkpoint:
			checkpoint_reached.emit(node.checkpoint_name)
		
		# Draw the path (single node, no lines)
		draw_node_path()
		calculate_nodes_along_selected_path()
	else:
		# Continue or modify existing path
		if node == selected_node and selected_path.size() > 1:
			remove_node_from_path()
		elif node_intersects_selected_path(node):
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

func remove_node_from_path():
	if selected_path.size() <= 1:
		return
		
	# Calculate the distance of the line segment being removed
	var removed_node = selected_node
	var previous_node = selected_path[selected_path.size() - 2]
	
	# Remove the node from the path
	selected_path.remove_at(selected_path.size() - 1)
	
	# Restore checkpoint appearance if the removed node was a checkpoint
	if removed_node.checkpoint:
		removed_node.restore_checkpoint_appearance()
		# Emit checkpoint reset signal to update tracking
		checkpoint_reset.emit(removed_node.checkpoint_name)
	
	# Increase energy based on the distance of the removed line segment
	var distance = previous_node.position.distance_to(removed_node.position)
	PlayerEnergy.increase_energy(distance)
	print("Energy increased by ", distance, ". Current energy: ", PlayerEnergy.get_energy())
	
	# Remove the node from placed_nodes and the scene
	placed_nodes.erase(removed_node)
	removed_node.queue_free()
	
	if (selected_path.size() == 0):
		selected_node = null
	else:
		selected_node = selected_path[selected_path.size() - 1]
		selected_node.make_visible()
		selected_node.toggle_selection()
	
	# Redraw the path after removing the node
	draw_node_path()
	calculate_nodes_along_selected_path()

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

# Handle energy depletion
func _on_energy_depleted():
	print("Energy depleted! Cannot draw more paths.")
	# You could add visual feedback here, like disabling node selection
	# or showing a game over message
