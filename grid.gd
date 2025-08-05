extends Node2D

# Grid configuration
const GRID_SIZE = 10
const PATHNODE_SCENE = preload("res://pathnode.tscn")

# Grid data structure
var grid_nodes = []
var selected_node

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
		select_new_node(event.position)
		
# selects the node closes to where is clicked, or toggles the selected node to unselected
func select_new_node(clicked_pos):
	var target_node = get_closest_node(clicked_pos)
	if (selected_node == null):
		selected_node = target_node
		selected_node.toggle_selection()
	elif (selected_node != null):
		selected_node.toggle_selection()
		if (selected_node == target_node):
			selected_node = null
		else:
			selected_node = target_node
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
