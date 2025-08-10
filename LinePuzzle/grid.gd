extends Node2D

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

func _ready():
	generate_grid()
	init_spawn_point()


func init_spawn_point():
	var spawn_point = get_node_or_null("SpawnPoint")
	if spawn_point != null:
		var true_spawn_point = get_closest_node(spawn_point.position)
		spawn_point.show_closest_node_as_spawn_point(true_spawn_point)
		selected_path.append(true_spawn_point)
		selected_node = true_spawn_point
	else:
		print("ERROR: No spawn point found")


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

	draw_grid_border(start_x, start_y, spacing * GRID_SIZE, grid_height)

# draw a border around the grid. this should not have a collision shape, but should be visible
func draw_grid_border(start_x, start_y, width, height):
	var shape = Line2D.new()
	shape.points = [Vector2(start_x, start_y), Vector2(start_x + width, start_y), Vector2(start_x + width, start_y + height), Vector2(start_x, start_y + height), Vector2(start_x, start_y)]
	shape.width = 2
	# line2d color
	shape.default_color = Color.PINK
	add_child(shape)


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
	selected_node.make_invisible()
	selected_node.toggle_selection()
	selected_path.remove_at(selected_path.size() - 1)
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
	selected_node = closest_node
	selected_path.append(selected_node)
	selected_node.make_visible()
	selected_node.toggle_selection()

			
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
