extends Node2D

# Grid configuration
const GRID_SIZE = 10
const PATHNODE_SCENE = preload("res://pathnode.tscn")

# Grid data structure
var grid_nodes = []
var selected_node

# the path is a stack of nodes, with the top node being the last node added
var selected_path = []

func _ready():
	generate_grid()


func generate_grid():
	var grid_height = 500
	
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
	select_new_node(event_pos)		
	calculatePath()
	drawNodePath()


# the path is a stack of nodes, with the top node being the last node added
# if the selected node is a node not in the path, add it to the path
# if the selected node is the top node in the path, remove it from the path
func calculatePath():
	if (selected_node == null):
		return

	if (selected_path.has(selected_node)):
		# if the selected node is the top node in the path, remove it from the path
		if (selected_path[selected_path.size() - 1] == selected_node):
			selected_path.remove_at(selected_path.size() - 1)
			if (selected_path.size() > 0):
				selected_node = selected_path[selected_path.size() - 1]
				selected_path[selected_path.size()-1].make_visible()
				selected_node.toggle_selection()
			else:
				selected_node = null
	else:
		# if the selected node is not in the path, add it to the path
		selected_path.append(selected_node)


# iterate through the selected path and draw a line between each node
func drawNodePath():
	for child in $PathLines.get_children():
		child.queue_free()
		await child.tree_exited
	for i in range(selected_path.size() - 1):
		var line = Line2D.new()
		line.points = [selected_path[i].position, selected_path[i + 1].position]
		$PathLines.add_child(line)


# selects the node closes to where is clicked, or toggles the selected node to unselected
func select_new_node(clicked_pos):
	var closest_node = get_closest_node(clicked_pos)
	if (selected_path.size() == 0):
		selected_node = closest_node
		selected_node.toggle_selection()
	else:
		selected_node.make_invisible()
		selected_node.toggle_selection()
		if (selected_node != closest_node):
			selected_node = closest_node
			selected_node.make_visible()
			selected_node.toggle_selection()
		

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
