extends Node2D

# Grid configuration
const GRID_SIZE = 10
const PATHNODE_SCENE = preload("res://pathnode.tscn")

# Grid data structure
var grid_nodes = []

func _ready():
	generate_grid()

func generate_grid():
	var grid_height = 500
	
	# Calculate spacing between nodes
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
