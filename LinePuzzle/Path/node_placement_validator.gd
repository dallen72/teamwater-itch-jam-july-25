extends Node

# Singleton class for validating node placement on the map
# This class handles all validation logic including obstacle detection and path intersection

# Constants for collision detection
const TREE_COLLISION_RADIUS: int = 75
const COW_COLLISION_RADIUS: int = 75
const RAYCAST_COLLISION_MASK: int = 1

# Cache for frequently accessed nodes
var _cached_trees: Array = []
var _cached_cows: Array = []
var _cache_valid: bool = false

func _ready():
	print("NodePlacementValidator singleton ready")

# Main validation function that checks if a node can be placed at a given position
func can_place_node_at_position(pos: Vector2, existing_nodes: Array = []) -> bool:
	# Check for obstacles at the position
	if is_obstacle_at_position(pos):
		return false
	
	# Check if position is far enough from existing nodes
	for node in existing_nodes:
		if node.position.distance_to(pos) < Global.NODE_COLLISION_RADIUS:
			return false
	
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
	
	# Use cached obstacle lists for better performance
	_update_obstacle_cache(current_scene)
	
	# Check for Tree nodes
	for tree in _cached_trees:
		if tree.position.distance_to(pos) < TREE_COLLISION_RADIUS:
			return true
	
	# Check for Cow nodes  
	for cow in _cached_cows:
		if cow.position.distance_to(pos) < COW_COLLISION_RADIUS:
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

# Update the cached obstacle lists for better performance
func _update_obstacle_cache(current_scene: Node) -> void:
	# Only update cache if it's invalid or empty
	if _cache_valid and _cached_trees.size() > 0 and _cached_cows.size() > 0:
		return
	
	_cached_trees = current_scene.get_tree().get_nodes_in_group("Tree")
	_cached_cows = current_scene.get_tree().get_nodes_in_group("Cow")
	_cache_valid = true
	print("Updated obstacle cache - Trees: ", _cached_trees.size(), ", Cows: ", _cached_cows.size())

# Clear the obstacle cache (call this when the scene changes)
func clear_obstacle_cache() -> void:
	_cached_trees.clear()
	_cached_cows.clear()
	_cache_valid = false
	print("Cleared obstacle cache")


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
	
	# check if the path is too close to an existing node
	if node1_pos.distance_to(node2_pos) < Global.NODE_COLLISION_RADIUS or node2_pos.distance_to(node1_pos) < Global.NODE_COLLISION_RADIUS:
		result.reason = "Path is too close to an existing node"
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


# Get the energy cost for connecting two nodes
func get_connection_energy_cost(node1_pos: Vector2, node2_pos: Vector2) -> int:
	return int(node1_pos.distance_to(node2_pos))
