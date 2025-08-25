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
func can_place_node_at_position(pos: Vector2, from_node: Node2D = null) -> bool:
	# Check for obstacles at the position
	if is_obstacle_at_position(pos):
		return false
	
	# If we have a starting node, check path validity
	if from_node != null:
		if path_intersects_obstacles(from_node.position, pos):
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

# Check if a line between two points intersects with obstacles using raycasts
func path_intersects_obstacles(start_pos: Vector2, end_pos: Vector2) -> bool:
	print("Raycast from ", start_pos, " to ", end_pos)
	
	# Get the current scene tree
	var scene_tree = get_tree()
	if not scene_tree:
		return false
	
	# Get the current scene root
	var current_scene = scene_tree.current_scene
	if not current_scene:
		return false
	
	# Get the physics space for raycasting from the current scene
	var space_state = current_scene.get_world_2d().direct_space_state
	if not space_state:
		return false
	
	# Create raycast parameters
	var query = PhysicsRayQueryParameters2D.new()
	query.from = start_pos
	query.to = end_pos
	query.collision_mask = RAYCAST_COLLISION_MASK
	
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

# Get the energy cost for connecting two nodes
func get_connection_energy_cost(node1_pos: Vector2, node2_pos: Vector2) -> int:
	return int(node1_pos.distance_to(node2_pos))

# Check if a connection between two nodes is valid (including energy check)
func is_connection_valid(node1_pos: Vector2, node2_pos: Vector2, available_energy: int) -> bool:
	# Check if we have enough energy
	var energy_cost = get_connection_energy_cost(node1_pos, node2_pos)
	if available_energy < energy_cost:
		return false
	
	# Check if the path intersects obstacles
	if path_intersects_obstacles_alternative(node1_pos, node2_pos):
		return false
	
	return true
