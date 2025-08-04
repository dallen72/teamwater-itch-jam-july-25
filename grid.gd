extends Node2D

# Grid configuration
const GRID_SIZE = 15
const PATHNODE_SCENE = preload("res://pathnode.tscn")

# Grid data structure
var grid_nodes = []

func _ready():
	generate_grid()

func generate_grid():
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	var grid_height = viewport_size.y * 0.5  # Half the viewport height
	
	# Calculate spacing between nodes
	var spacing = grid_height / (GRID_SIZE - 1)
	
	# Calculate starting position to center the grid
	var start_x = -spacing * (GRID_SIZE - 1) * 0.5
	var start_y = -grid_height * 0.5
	
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
