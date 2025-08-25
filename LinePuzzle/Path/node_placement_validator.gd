extends Node

# Singleton class for validating node placement on the map
# This class handles all validation logic including obstacle detection and path intersection

# Constants for collision detection
const SCENERY_COLLISION_RADIUS: int = 30
const RAYCAST_COLLISION_MASK: int = 1

func _ready():
	print("NodePlacementValidator singleton ready")


# Main validation function that checks if a node can be placed at a given position
func can_place_node_at_position(pos: Vector2, existing_nodes: Array = []) -> bool:
	# if transition between level
	if existing_nodes.size() == 0:
		return false
	# check if energy is enough
	if (PlayerEnergy.get_energy() < get_connection_energy_cost(existing_nodes[-1].position, pos)):
		return false
	# Check for obstacles at the position
	elif is_obstacle_at_position(pos):
		return false
	elif path_intersects_obstacles_alternative(existing_nodes[-1].position, pos):
		return false
	# Check if position is far enough from existing nodes
	if (too_close_to_non_checkpoint_node(pos)):
		return false
	else:
		return true



# Check if there's an obstacle at the given position
func is_obstacle_at_position(pos: Vector2) -> bool:
	# Get the current scene tree
	var scene_tree = get_tree()
	if not scene_tree:
		return false
	
	# Get the current scene root
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return false
	
	# Check for Tree nodes
	for scenery in get_tree().get_nodes_in_group("Scenery"): # Check directly
		if scenery.position.distance_to(pos) < SCENERY_COLLISION_RADIUS:
			return true

	
	return false




# Alternative raycast method that checks multiple points along the path for more accuracy
func path_intersects_obstacles_alternative(start_pos: Vector2, end_pos: Vector2) -> bool:
	print("Alternative raycast from ", start_pos, " to ", end_pos)
	
	# Get the current scene tree
	var scene_tree = get_tree()
	if not scene_tree:
		return false
	
	# Get the current scene root
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return false
	
	var space_state = current_scene.get_world_2d().direct_space_state
	if not space_state:
		return false
	
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
		query.collision_mask = RAYCAST_COLLISION_MASK
		
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result["collider"]
			if collider and ("Tree" in collider.name or "Cow" in collider.name):
				print("Alternative raycast hit obstacle: ", collider.name, " at segment ", i)
				return true
	
	print("Alternative raycast hit nothing")
	return false





# Comprehensive validation function that checks both energy and obstacles
# Returns a dictionary with validation result and details
func validate_node_connection(node1_pos: Vector2, node2_pos: Vector2, available_energy: int) -> Dictionary:
	var result = {
		"valid": false,
		"reason": "",
		"energy_cost": 0,
		"energy_sufficient": false,
		"path_clear": false
	}
	
	# Calculate energy cost
	result.energy_cost = int(node1_pos.distance_to(node2_pos))
	result.energy_sufficient = available_energy >= result.energy_cost
	
	# Check if path is clear of obstacles
	result.path_clear = not path_intersects_obstacles_alternative(node1_pos, node2_pos)

	if (too_close_to_non_checkpoint_node(node2_pos)):
		result.reason = "Node position selection is too close to an existing node"
		return result

	# Determine if connection is valid
	if not result.energy_sufficient:
		result.reason = "Insufficient energy"
	elif not result.path_clear:
		result.reason = "Path intersects obstacles"
	else:
		result.valid = true
		result.reason = "Connection valid"
	
	return result


func too_close_to_non_checkpoint_node(mouse_pos: Vector2) -> bool:
	# get the checkpoints from the scene	
	var checkpoints = get_tree().get_nodes_in_group("CheckPoint")

	print("debug, mouse_pos: " + str(mouse_pos))

	# check if the path is too close to an existing node
	for node in Global.placed_nodes:
		if mouse_pos.distance_to(node.position) < Global.NODE_COLLISION_RADIUS:
			for checkpoint in checkpoints:
				if checkpoint.position.distance_to(mouse_pos) < Global.NODE_COLLISION_RADIUS:
					return false
			return true

	return false


# Get the energy cost for connecting two nodes
func get_connection_energy_cost(node1_pos: Vector2, node2_pos: Vector2) -> int:
	return int(node1_pos.distance_to(node2_pos))
